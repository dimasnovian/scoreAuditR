download_whr <- function(directory = "whr_data", overwrite = FALSE) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  archive <- file.path(directory, "world-happiness-report-2024.zip")
  if (file.exists(archive) && !overwrite) stop("Download exists; set overwrite = TRUE to replace it.")
  url <- paste0("https://www.kaggle.com/api/v1/datasets/download/",
    "jainaru/world-happiness-report-2024-yearly-updated")
  status <- tryCatch(utils::download.file(url, archive, mode = "wb", quiet = FALSE),
    error = function(e) stop("Download failed. Download manually from the Kaggle dataset page. ", conditionMessage(e)))
  if (!identical(status, 0L) && !identical(status, 0)) stop("Kaggle download did not complete.")
  files <- tryCatch(utils::unzip(archive, list = TRUE), error = function(e) NULL)
  if (is.null(files) || !nrow(files)) stop("Response is not a dataset ZIP. Use Kaggle's Download button.")
  # Reject traversal, absolute paths, Windows drive prefixes and backslashes.
  unsafe <- grepl("(^/|^[A-Za-z]:|\\\\|(^|/)\\.\\.(/|$))", files$Name)
  if (any(unsafe)) stop("Unsafe archive paths rejected.")
  csv <- files$Name[grepl("[.]csv$", files$Name, ignore.case = TRUE)]
  if (!length(csv)) stop("Dataset archive contains no CSV files.")
  destinations <- file.path(directory, csv)
  if (!overwrite && any(file.exists(destinations))) stop("CSV files already exist; refusing to overwrite.")
  utils::unzip(archive, files = csv, exdir = directory)
  utils::write.csv(data.frame(dataset = "jainaru/world-happiness-report-2024-yearly-updated",
    url = url, downloaded_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    archive_md5 = unname(tools::md5sum(archive))), file.path(directory, "download_manifest.csv"), row.names = FALSE)
  normalizePath(destinations)
}

run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) stop("Install the optional interface first: install.packages('shiny')")
  app <- system.file("shiny", package = "scoreAuditR")
  if (!nzchar(app)) stop("Install scoreAuditR before running its interface.")
  shiny::runApp(app, ...)
}
