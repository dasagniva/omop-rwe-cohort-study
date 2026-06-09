# =============================================================================
# 05_sensitivity_analysis.R
# Robustness: negative-control calibration, empirical null, and E-values.
# =============================================================================

suppressPackageStartupMessages({
  library(CohortMethod)
  library(EmpiricalCalibration)
})

source(file.path("R", "utils.R"))

# Pre-specified negative-control outcomes: SNOMED conditions with no plausible
# causal relationship to either NSAID exposure, used to estimate and correct for
# residual systematic error (confounding + measurement bias).
#
# Selected to span a range of domains while being causally unrelated to NSAID use:
#   192671  Gastrointestinal hemorrhage       <- excluded (is the primary outcome)
#   4112343 Acute viral pharyngitis
#   40481087 Viral sinusitis
#   372328  Otitis media
#   4058680 Sprain of ankle
#   434203  Ingrowing toenail
#   136368  Fracture of forearm
#   4299298 Acute conjunctivitis
negative_control_ids <- c(
  4112343L,   # Acute viral pharyngitis
  40481087L,  # Viral sinusitis
  372328L,    # Otitis media
  4058680L,   # Sprain of ankle
  434203L,    # Ingrowing toenail
  136368L,    # Fracture of forearm
  4299298L    # Acute conjunctivitis
)

#' Estimate log-HR and SE for each negative-control outcome using the same
#' cohorts and PS model as the primary analysis.
get_negative_control_estimates <- function(cdm, nc_ids, target_id, comparator_id, cm_data) {
  log_step(sprintf("Estimating effects for %d negative-control outcomes", length(nc_ids)))

  results <- lapply(nc_ids, function(nc_id) {
    tryCatch({
      study_pop <- CohortMethod::createStudyPopulation(
        cohortMethodData = cm_data,
        outcomeId        = nc_id,
        createStudyPopulationArgs = CohortMethod:::createCreateStudyPopulationArgs(
          removeSubjectsWithPriorOutcome = TRUE,
          riskWindowStart               = 1,
          startAnchor                   = "cohort start",
          riskWindowEnd                 = 0,
          endAnchor                     = "cohort end"
        )
      )
      ps <- CohortMethod::createPs(
        cohortMethodData = cm_data,
        population       = study_pop,
        createPsArgs     = CohortMethod:::createCreatePsArgs()
      )
      matched_nc <- CohortMethod::matchOnPs(
        population    = ps,
        matchOnPsArgs = CohortMethod::createMatchOnPsArgs(
          caliper = 0.2, caliperScale = "standardized logit"
        )
      )
      model_nc <- CohortMethod::fitOutcomeModel(
        population          = matched_nc,
        cohortMethodData    = cm_data,
        fitOutcomeModelArgs = CohortMethod::createFitOutcomeModelArgs(modelType = "cox")
      )
      if (model_nc$outcomeModelStatus != "OK") {
        log_step(sprintf("  NC %d: no outcomes in matched population, skipping", nc_id))
        return(NULL)
      }
      stats <- model_nc$outcomeModelTreatmentEstimate
      if (is.null(stats) || nrow(stats) == 0) return(NULL)
      data.frame(outcomeId = nc_id, logRr = stats$logRr, seLogRr = stats$seLogRr)
    }, error = function(e) {
      log_step(sprintf("  Skipping NC %d: %s", nc_id, conditionMessage(e)))
      NULL
    })
  })

  nc_df <- do.call(rbind, Filter(Negate(is.null), results))
  save_output(nc_df, "negative_control_estimates.csv")
  nc_df
}

#' Estimate the empirical null from negative-control effect estimates and
#' calibrate the primary estimate against it.
calibrate_estimate <- function(primary_logrr, primary_se, nc_estimates) {
  log_step("Fitting empirical null distribution from negative controls")
  null_dist <- EmpiricalCalibration::fitNull(
    logRr   = nc_estimates$logRr,
    seLogRr = nc_estimates$seLogRr
  )

  log_step("Calibrating the primary estimate")
  calibrated <- EmpiricalCalibration::calibrateP(
    null    = null_dist,
    logRr   = primary_logrr,
    seLogRr = primary_se
  )

  save_plot(
    EmpiricalCalibration::plotCalibrationEffect(
      logRrNegatives   = nc_estimates$logRr,
      seLogRrNegatives = nc_estimates$seLogRr,
      logRrPositives   = primary_logrr,
      seLogRrPositives = primary_se
    ),
    "negative_control_calibration.png"
  )
  log_step("Calibration plot written to output/")
  calibrated
}

#' Compute the E-value for the point estimate and the confidence limit nearer the null.
#' For HR < 1, the formula is applied to 1/HR (symmetry around the null).
compute_evalue <- function(hr, lcl, ucl) {
  log_step("Computing E-values for unmeasured confounding")
  evalue <- function(x) {
    x <- ifelse(x < 1, 1 / x, x)
    x + sqrt(x * (x - 1))
  }
  limit  <- if (hr > 1) lcl else ucl
  result <- data.frame(hr = hr, lcl = lcl, ucl = ucl,
                       evalue_point = evalue(hr),
                       evalue_limit = evalue(limit))
  save_output(result, "evalues.csv")
  log_step(sprintf("  E-value (point): %.2f  |  E-value (CI limit): %.2f",
                   result$evalue_point, result$evalue_limit))
  result
}
