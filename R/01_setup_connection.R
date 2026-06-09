# =============================================================================
# 01_setup_connection.R
# Establish a connection to the OMOP CDM and build a CDM reference.
#
# This study runs on Eunomia, the OHDSI public teaching dataset (Synthea-derived
# synthetic records + CMS SynPUF), so no database server and no data-access
# agreement are required. Eunomia runs in-process in R.
# =============================================================================

# --- One-time setup -----------------------------------------------------------
# Eunomia downloads its sample CDM to a local folder. Set this once in your
# .Renviron (run usethis::edit_r_environ() and add the line below), then restart R:
#
#   EUNOMIA_DATA_FOLDER = "~/eunomia_data"
#
# Package installation (one time):
#   install.packages("remotes")
#   install.packages(c("DatabaseConnector", "SqlRender"))
#   remotes::install_github("OHDSI/Eunomia")
#   remotes::install_github("OHDSI/CohortGenerator")
#   remotes::install_github("OHDSI/CohortMethod")
#   remotes::install_github("OHDSI/FeatureExtraction")

suppressPackageStartupMessages({
  library(DatabaseConnector)
})

source(file.path("R", "utils.R"))

#' Connect to the GiBleed OMOP CDM (SQLite, bundled from Eunomia v1.0.3).
#'
#' Returns a list with the open connection, connectionDetails, and the schema
#' names used throughout the study. The clinical tables and the OMOP standard
#' vocabularies both live in the 'main' schema in SQLite.
connect_cdm <- function() {
  db_path <- path.expand("~/eunomia_data/cdm.sqlite")
  if (!file.exists(db_path)) {
    stop("GiBleed SQLite database not found at: ", db_path,
         "\nRun extras/install_packages.R to set up the database.")
  }
  log_step(sprintf("Connecting to GiBleed SQLite CDM (%s)", db_path))
  connection_details <- DatabaseConnector::createConnectionDetails(
    dbms   = "sqlite",
    server = db_path
  )

  log_step("Opening connection to the OMOP CDM")
  connection <- DatabaseConnector::connect(connection_details)

  schemas <- list(
    cdm_database_schema    = "main",  # OMOP CDM clinical + vocabulary tables
    cohort_database_schema = "main",  # where generated cohorts are written
    cohort_table           = "study_cohorts"
  )

  # Quick sanity check: how many persons are in the CDM?
  n_person <- DatabaseConnector::querySql(
    connection, "SELECT COUNT(*) AS n FROM main.person;"
  )[[1]][1]
  log_step(sprintf("Connected. CDM contains %s persons.", format(n_person, big.mark = ",")))

  list(
    connection         = connection,
    connection_details = connection_details,
    schemas            = schemas
  )
}

#' Cleanly close the CDM connection.
disconnect_cdm <- function(cdm) {
  DatabaseConnector::disconnect(cdm$connection)
  log_step("Connection closed.")
}
