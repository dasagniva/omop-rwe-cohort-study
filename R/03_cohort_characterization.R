# =============================================================================
# 03_cohort_characterization.R
# Baseline characterisation of the exposure cohorts ("Table 1") and attrition.
# =============================================================================

suppressPackageStartupMessages({
  library(DatabaseConnector)
  library(FeatureExtraction)
})

source(file.path("R", "utils.R"))

#' Extract baseline covariates for the two exposure cohorts and build a
#' comparison table with standardised mean differences (SMDs).
characterize_cohorts <- function(cdm, target_id, comparator_id) {
  log_step("Defining baseline covariate settings (365-day pre-index window)")
  covariate_settings <- FeatureExtraction::createDefaultCovariateSettings()

  log_step("Extracting covariates for target cohort")
  covars_target <- FeatureExtraction::getDbCovariateData(
    connection           = cdm$connection,
    cdmDatabaseSchema    = cdm$schemas$cdm_database_schema,
    cohortDatabaseSchema = cdm$schemas$cohort_database_schema,
    cohortTable          = cdm$schemas$cohort_table,
    cohortId             = target_id,
    covariateSettings    = covariate_settings,
    aggregated           = TRUE
  )

  log_step("Extracting covariates for comparator cohort")
  covars_comparator <- FeatureExtraction::getDbCovariateData(
    connection           = cdm$connection,
    cdmDatabaseSchema    = cdm$schemas$cdm_database_schema,
    cohortDatabaseSchema = cdm$schemas$cohort_database_schema,
    cohortTable          = cdm$schemas$cohort_table,
    cohortId             = comparator_id,
    covariateSettings    = covariate_settings,
    aggregated           = TRUE
  )

  log_step("Building Table 1 with standardised mean differences")
  table1 <- FeatureExtraction::computeStandardizedDifference(
    covariateData1 = covars_target,
    covariateData2 = covars_comparator
  )

  save_output(table1, "table1_baseline_characteristics.csv")
  log_step("Table 1 written to output/")
  invisible(table1)
}
