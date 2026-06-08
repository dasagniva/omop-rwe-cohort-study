# =============================================================================
# 04_comparative_analysis.R
# Propensity-score estimation, matching/stratification, covariate-balance
# diagnostics, and the Cox comparative outcome model.
#
# Implements the primary (on-treatment, PS-matched) and co-primary
# (intention-to-treat) estimands defined in the SAP.
# =============================================================================

suppressPackageStartupMessages({
  library(CohortMethod)
  library(FeatureExtraction)
})

source(file.path("R", "utils.R"))

#' Assemble the CohortMethod data object (cohorts, covariates, outcomes).
#' Pass additional_outcome_ids to load negative-control outcomes in the same call.
build_cm_data <- function(cdm, target_id, comparator_id, outcome_id,
                          additional_outcome_ids = integer(0)) {
  log_step("Assembling CohortMethod data (large-scale covariates)")
  covariate_settings <- FeatureExtraction::createDefaultCovariateSettings()
  all_outcome_ids    <- unique(c(outcome_id, additional_outcome_ids))

  CohortMethod::getDbCohortMethodData(
    connectionDetails      = cdm$connection_details,
    cdmDatabaseSchema      = cdm$schemas$cdm_database_schema,
    targetId               = target_id,
    comparatorId           = comparator_id,
    outcomeIds             = all_outcome_ids,
    exposureDatabaseSchema = cdm$schemas$cohort_database_schema,
    exposureTable          = cdm$schemas$cohort_table,
    outcomeDatabaseSchema  = cdm$schemas$cohort_database_schema,
    outcomeTable           = cdm$schemas$cohort_table,
    covariateSettings      = covariate_settings
  )
}

#' Fit the large-scale propensity score (LASSO logistic regression).
estimate_ps <- function(cm_data, outcome_id) {
  log_step("Creating study population (applying time-at-risk)")
  study_pop <- CohortMethod::createStudyPopulation(
    cohortMethodData              = cm_data,
    outcomeId                     = outcome_id,
    removeSubjectsWithPriorOutcome = TRUE,
    riskWindowStart               = 1,
    riskWindowEnd                 = 0,
    addExposureDaysToEnd          = TRUE   # on-treatment window
  )

  log_step("Fitting large-scale propensity score (LASSO)")
  ps <- CohortMethod::createPs(
    cohortMethodData = cm_data,
    population       = study_pop
  )

  log_step("Saving PS distribution and preference-score overlap plots")
  save_plot(CohortMethod::plotPs(ps), "ps_distribution.png")
  list(study_pop = study_pop, ps = ps)
}

#' Match on the PS and check covariate balance.
match_and_balance <- function(cm_data, ps) {
  log_step("1:1 matching on the logit of the PS (caliper 0.2 SD)")
  matched <- CohortMethod::matchOnPs(ps, caliper = 0.2, caliperScale = "standardized logit")

  log_step("Computing covariate balance (SMDs) after matching")
  balance <- CohortMethod::computeCovariateBalance(matched, cm_data)
  save_plot(CohortMethod::plotCovariateBalanceScatterPlot(balance),
            "covariate_balance.png")
  save_output(balance, "covariate_balance.csv")
  matched
}

#' Fit the Cox outcome model and return the hazard ratio.
fit_outcome_model <- function(cm_data, matched, label) {
  log_step(sprintf("Fitting Cox outcome model (%s)", label))
  model <- CohortMethod::fitOutcomeModel(
    population       = matched,
    cohortMethodData = cm_data,
    modelType        = "cox"
  )
  stats <- model$outcomeModelTreatmentEstimate
  save_output(stats, sprintf("outcome_model_%s.csv", label))
  hr <- exp(stats$logRr)
  ci  <- exp(c(stats$logLb95, stats$logUb95))
  log_step(sprintf("%s HR = %.3f (95%% CI %.3f–%.3f)", label, hr, ci[1], ci[2]))
  model
}
