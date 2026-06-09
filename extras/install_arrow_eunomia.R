user_lib <- path.expand("~/R/library")
.libPaths(c(user_lib, .libPaths()))

posit <- "https://packagemanager.posit.co/cran/__linux__/noble/latest"
cran  <- "https://cloud.r-project.org"

cat("[1/2] Installing arrow from Posit binary repo...\n")
install.packages("arrow", lib = user_lib, repos = c(posit, cran), quiet = FALSE)
cat("arrow installed:", "arrow" %in% installed.packages()[, "Package"], "\n")

cat("[2/2] Installing Eunomia from GitHub...\n")
remotes::install_github("OHDSI/Eunomia", lib = user_lib, upgrade = "never",
                        INSTALL_opts = "--no-build-vignettes")
cat("Eunomia installed:", "Eunomia" %in% installed.packages()[, "Package"], "\n")
