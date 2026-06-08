# =============================================================================
# utils.R
# Shared helpers: logging, output paths, save wrappers.
# Sourced by every stage script.
# =============================================================================

OUTPUT_DIR <- "output"

#' Timestamped progress logging.
log_step <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
}

#' Ensure the output directory exists.
ensure_output_dir <- function() {
  if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
}

#' Save a data frame to output/ as CSV.
save_output <- function(x, filename) {
  ensure_output_dir()
  utils::write.csv(x, file.path(OUTPUT_DIR, filename), row.names = FALSE)
}

#' Save a plot object (ggplot or base) to output/.
save_plot <- function(plot_obj, filename, width = 8, height = 6, dpi = 150) {
  ensure_output_dir()
  path <- file.path(OUTPUT_DIR, filename)
  if (inherits(plot_obj, "ggplot")) {
    ggplot2::ggsave(path, plot_obj, width = width, height = height, dpi = dpi)
  } else {
    grDevices::png(path, width = width * dpi, height = height * dpi, res = dpi)
    print(plot_obj)
    grDevices::dev.off()
  }
}

#' Capture the R session for reproducibility.
capture_session <- function() {
  if (!dir.exists("extras")) dir.create("extras")
  writeLines(capture.output(utils::sessionInfo()), "extras/session_info.txt")
}
