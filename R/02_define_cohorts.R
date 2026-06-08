# =============================================================================
# 02_define_cohorts.R
# Build the target, comparator, and outcome cohorts.
#
# Cohort logic is expressed over OMOP standard concept sets:
#   - Drugs   -> RxNorm ingredients and their descendants
#   - Outcomes-> SNOMED condition concepts (ICD-9/10 source codes map in)
# =============================================================================

suppressPackageStartupMessages({
  library(DatabaseConnector)
  library(SqlRender)
  library(CohortGenerator)
})

source(file.path("R", "utils.R"))

# --- Concept-set specification -----------------------------------------------
concept_sets <- list(
  target_exposure = list(
    name        = "Celecoxib (selective COX-2 inhibitor) — new users",
    vocabulary  = "RxNorm",
    ingredients = c("celecoxib")
  ),
  comparator_exposure = list(
    name       = "Non-selective NSAIDs — new users",
    vocabulary = "RxNorm",
    ingredients = c("diclofenac", "ibuprofen", "naproxen")
  ),
  outcome = list(
    name       = "Gastrointestinal haemorrhage",
    vocabulary = "SNOMED",
    conditions = c("Gastrointestinal hemorrhage")
  )
)

eligibility <- list(
  prior_observation_days = 365L,
  washout_days           = 365L,
  min_age                = 18L,
  exclude_prior_outcome  = TRUE
)

#' Resolve concept names to standard concept_ids via vocabulary + ancestor expansion.
#'
#' Queries main.concept for the named concepts (case-insensitive, standard, valid),
#' then expands to all descendants via main.concept_ancestor. Falls back to the
#' ancestor concept IDs themselves if the ancestor table is empty for these concepts.
resolve_concepts <- function(cdm, names, domain) {
  log_step(sprintf("Resolving %d concept name(s) in domain '%s'", length(names), domain))

  quoted <- paste(sprintf("'%s'", names), collapse = ", ")

  sql_anc <- sprintf(
    "SELECT DISTINCT ca.descendant_concept_id AS concept_id
     FROM main.concept c
     JOIN main.concept_ancestor ca ON c.concept_id = ca.ancestor_concept_id
     WHERE LOWER(c.concept_name) IN (%s)
       AND c.standard_concept = 'S'
       AND (c.invalid_reason IS NULL OR c.invalid_reason = '')",
    paste(sprintf("'%s'", tolower(names)), collapse = ", ")
  )
  rows <- DatabaseConnector::querySql(cdm$connection, sql_anc)
  ids  <- rows$CONCEPT_ID

  if (length(ids) == 0) {
    sql_direct <- sprintf(
      "SELECT concept_id
       FROM main.concept
       WHERE LOWER(concept_name) IN (%s)
         AND standard_concept = 'S'
         AND (invalid_reason IS NULL OR invalid_reason = '')",
      paste(sprintf("'%s'", tolower(names)), collapse = ", ")
    )
    rows <- DatabaseConnector::querySql(cdm$connection, sql_direct)
    ids  <- rows$CONCEPT_ID
  }

  log_step(sprintf("  -> %d concept ID(s) resolved for: %s",
                   length(ids), paste(names, collapse = ", ")))
  ids
}

# --- Cohort SQL templates (SQL Server dialect; SqlRender translates to SQLite) ---

.drug_cohort_sql <- "
DELETE FROM @cohort_database_schema.@cohort_table
WHERE cohort_definition_id = @cohort_definition_id;

INSERT INTO @cohort_database_schema.@cohort_table (
  cohort_definition_id,
  subject_id,
  cohort_start_date,
  cohort_end_date
)
SELECT
  @cohort_definition_id                     AS cohort_definition_id,
  fe.person_id                              AS subject_id,
  fe.index_date                             AS cohort_start_date,
  op.observation_period_end_date            AS cohort_end_date
FROM (
  SELECT person_id, MIN(drug_exposure_start_date) AS index_date
  FROM @cdm_database_schema.drug_exposure
  WHERE drug_concept_id IN (@concept_ids)
  GROUP BY person_id
) fe
JOIN @cdm_database_schema.observation_period op
  ON  fe.person_id  = op.person_id
  AND fe.index_date >= op.observation_period_start_date
  AND fe.index_date <= op.observation_period_end_date
JOIN @cdm_database_schema.person p
  ON  fe.person_id  = p.person_id
WHERE
  DATEDIFF(DAY, op.observation_period_start_date, fe.index_date) >= @prior_observation_days
  AND (YEAR(fe.index_date) - p.year_of_birth) >= @min_age
  AND NOT EXISTS (
    SELECT 1
    FROM @cdm_database_schema.drug_exposure prior_de
    WHERE prior_de.person_id          = fe.person_id
      AND prior_de.drug_concept_id   IN (@concept_ids)
      AND prior_de.drug_exposure_start_date <  fe.index_date
      AND prior_de.drug_exposure_start_date >= DATEADD(DAY, -@washout_days, fe.index_date)
  );
"

.outcome_cohort_sql <- "
DELETE FROM @cohort_database_schema.@cohort_table
WHERE cohort_definition_id = @cohort_definition_id;

INSERT INTO @cohort_database_schema.@cohort_table (
  cohort_definition_id,
  subject_id,
  cohort_start_date,
  cohort_end_date
)
SELECT DISTINCT
  @cohort_definition_id                     AS cohort_definition_id,
  co.person_id                              AS subject_id,
  co.condition_start_date                   AS cohort_start_date,
  COALESCE(co.condition_end_date,
           DATEADD(DAY, 1, co.condition_start_date)) AS cohort_end_date
FROM @cdm_database_schema.condition_occurrence co
WHERE co.condition_concept_id IN (@concept_ids);
"

#' Execute a rendered + translated SQL statement and return affected row count.
.run_cohort_sql <- function(connection, template, render_args, target_dialect = "sqlite") {
  sql <- do.call(SqlRender::render, c(list(sql = template), render_args))
  sql <- SqlRender::translate(sql, targetDialect = target_dialect)
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
}

#' Generate the study cohorts into the cohort table.
generate_cohorts <- function(cdm, target_ids, comparator_ids, outcome_ids) {
  if (length(target_ids) == 0 || length(comparator_ids) == 0 || length(outcome_ids) == 0)
    stop("One or more concept-ID sets are empty — check vocabulary resolution.")

  log_step("Creating cohort table")
  cohort_table_names <- CohortGenerator::getCohortTableNames(cdm$schemas$cohort_table)
  CohortGenerator::createCohortTables(
    connection           = cdm$connection,
    cohortDatabaseSchema = cdm$schemas$cohort_database_schema,
    cohortTableNames     = cohort_table_names
  )

  common_args <- list(
    cdm_database_schema    = cdm$schemas$cdm_database_schema,
    cohort_database_schema = cdm$schemas$cohort_database_schema,
    cohort_table           = cdm$schemas$cohort_table,
    prior_observation_days = eligibility$prior_observation_days,
    washout_days           = eligibility$washout_days,
    min_age                = eligibility$min_age
  )

  log_step("Generating target cohort (celecoxib new users)")
  .run_cohort_sql(cdm$connection, .drug_cohort_sql,
    c(common_args, list(cohort_definition_id = 1L, concept_ids = target_ids)))

  log_step("Generating comparator cohort (non-selective NSAID new users)")
  .run_cohort_sql(cdm$connection, .drug_cohort_sql,
    c(common_args, list(cohort_definition_id = 2L, concept_ids = comparator_ids)))

  log_step("Generating outcome cohort (GI haemorrhage)")
  .run_cohort_sql(cdm$connection, .outcome_cohort_sql,
    c(common_args, list(cohort_definition_id = 3L, concept_ids = outcome_ids)))

  # Log cohort sizes
  counts_sql <- sprintf(
    "SELECT cohort_definition_id, COUNT(*) AS n
     FROM %s.%s GROUP BY cohort_definition_id;",
    cdm$schemas$cohort_database_schema, cdm$schemas$cohort_table
  )
  counts <- DatabaseConnector::querySql(cdm$connection, counts_sql)
  log_step("Cohort sizes:")
  for (i in seq_len(nrow(counts))) {
    label <- switch(as.character(counts$COHORT_DEFINITION_ID[i]),
                    "1" = "Target (celecoxib)",
                    "2" = "Comparator (non-selective NSAIDs)",
                    "3" = "Outcome (GI haemorrhage)",
                    "Unknown")
    log_step(sprintf("  Cohort %d — %s: %d rows",
                     counts$COHORT_DEFINITION_ID[i], label, counts$N[i]))
  }

  invisible(cohort_table_names)
}
