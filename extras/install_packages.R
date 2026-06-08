# Run this once to install all study dependencies.
# Requires R >= 4.2 and an internet connection.

user_lib <- path.expand("~/R/library")
if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
.libPaths(c(user_lib, .libPaths()))

install.packages("remotes", lib = user_lib, repos = "https://cloud.r-project.org")

cran_pkgs <- c("DatabaseConnector", "SqlRender", "FeatureExtraction")
remotes::install_cran(cran_pkgs, lib = user_lib,
                      repos = "https://cloud.r-project.org", upgrade = "never")

github_pkgs <- c(
  "OHDSI/Eunomia",
  "OHDSI/CohortGenerator",
  "OHDSI/CohortMethod",
  "OHDSI/EmpiricalCalibration"
)
for (pkg in github_pkgs) remotes::install_github(pkg, lib = user_lib, upgrade = "never")

message("All packages installed. Restart R before running the study.")
