# =============================================================================
# run_study.R
# Master script — runs the full RWE comparative-cohort study end to end.
#
# Usage (from the repository root, in R):
#   source("analysis/run_study.R")
# =============================================================================

# --- Load all stages ---------------------------------------------------------
source(file.path("R", "01_setup_connection.R"))
source(file.path("R", "02_define_cohorts.R"))
source(file.path("R", "03_cohort_characterization.R"))
source(file.path("R", "04_comparative_analysis.R"))
source(file.path("R", "05_sensitivity_analysis.R"))

# Cohort identifiers (assigned during cohort generation)
TARGET_ID     <- 1L   # Celecoxib new users
COMPARATOR_ID <- 2L   # Non-selective NSAID new users
OUTCOME_ID    <- 3L   # GI haemorrhage

.run_study <- function() {
  log_step("=== STUDY START: NSAID GI-haemorrhage comparative cohort ===")

  # 1. Connect ------------------------------------------------------------------
  cdm <- connect_cdm()
  on.exit(disconnect_cdm(cdm), add = TRUE)

  # 2. Define & generate cohorts ------------------------------------------------
  target_ids     <- resolve_concepts(cdm, concept_sets$target_exposure$ingredients, "Drug")
  comparator_ids <- resolve_concepts(cdm, concept_sets$comparator_exposure$ingredients, "Drug")
  outcome_ids    <- resolve_concepts(cdm, concept_sets$outcome$conditions, "Condition")
  generate_cohorts(cdm, target_ids, comparator_ids, outcome_ids)

  # 3. Characterise -------------------------------------------------------------
  characterize_cohorts(cdm, TARGET_ID, COMPARATOR_ID)

  # 4. Comparative analysis -----------------------------------------------------
  cm_data   <- build_cm_data(cdm, TARGET_ID, COMPARATOR_ID, OUTCOME_ID,
                             additional_outcome_ids = negative_control_ids,
                             exclude_concept_ids    = c(target_ids, comparator_ids))
  ps_result <- estimate_ps(cm_data, OUTCOME_ID)
  matched   <- match_and_balance(cm_data, ps_result$ps)

  model_ot  <- fit_outcome_model(cm_data, matched, label = "on_treatment")

  # 5. Sensitivity --------------------------------------------------------------
  hr_stats      <- model_ot$outcomeModelTreatmentEstimate
  primary_logrr <- hr_stats$logRr
  primary_se    <- hr_stats$seLogRr

  if (length(negative_control_ids) > 0) {
    nc_estimates <- get_negative_control_estimates(cdm, negative_control_ids,
                                                   TARGET_ID, COMPARATOR_ID,
                                                   cm_data)
    if (!is.null(nc_estimates) && nrow(nc_estimates) >= 3) {
      calibrated <- calibrate_estimate(primary_logrr, primary_se, nc_estimates)
    } else {
      log_step("Skipping empirical calibration — insufficient negative-control estimates (need >= 3).")
    }
  } else {
    log_step("Skipping empirical calibration — negative_control_ids is empty.")
  }

  compute_evalue(
    hr  = exp(primary_logrr),
    lcl = exp(primary_logrr - 1.96 * primary_se),
    ucl = exp(primary_logrr + 1.96 * primary_se)
  )

  capture_session()
  log_step("=== STUDY COMPLETE — see output/ for tables and figures ===")
}

.run_study()
