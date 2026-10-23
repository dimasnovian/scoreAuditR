read_whr <- function(path, year = NULL, source_url = NULL) {
  if (length(path) != 1L || !file.exists(path)) stop("CSV file does not exist.")
  d <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                       na.strings = c("", "NA", "N/A", ".."), fileEncoding = "UTF-8-BOM")
  original <- names(d)
  names(d) <- .clean(original)
  if (anyDuplicated(names(d))) stop("Column names collide after normalization.")
  aliases <- list(country = c("country_name", "countryname", "country"),
    year = c("year"), life_ladder = c("life_ladder", "ladder_score", "happiness_score", "score"),
    log_gdp_per_capita = c("log_gdp_per_capita", "logged_gdp_per_capita"),
    healthy_life_expectancy = c("healthy_life_expectancy_at_birth", "healthy_life_expectancy"))
  for (to in names(aliases)) {
    hits <- intersect(aliases[[to]], names(d))
    if (length(hits) > 1L) stop("Ambiguous mapping for ", to, "; rename columns explicitly.")
    if (length(hits)) names(d)[match(hits, names(d))] <- to
  }
  if (!"year" %in% names(d)) {
    if (is.null(year)) stop("No year column. Supply year explicitly for a single-report table.")
    .scalar(year, "year", 1800, 3000, TRUE)
    d$year <- year
  }
  if (!all(c("country", "life_ladder") %in% names(d)))
    stop("Expected Country name and Life Ladder (or Ladder score) columns.")
  if (any(grepl("^explained_by_", names(d))))
    warning("Explained-by components detected. These are not raw contextual indicators; do not use as predictors.")
  if (length(unique(d$year)) < 2L)
    warning("Single-year/report table: forecasting and consecutive-year gap analysis require a genuine annual panel.")
  attr(d, "provenance") <- list(source_url = source_url, file = basename(path),
    md5 = unname(tools::md5sum(path)), imported_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    original_columns = original, normalized_columns = names(d), data_type = "imported CSV")
  d
}

validate_panel <- function(data, id = "country", time = "year", target = "life_ladder",
                           predictors) {
  if (!is.data.frame(data) || nrow(data) < 4L) stop("data must contain at least four rows.")
  if (anyDuplicated(names(data))) stop("Duplicate column names.")
  if (length(id) != 1L || length(time) != 1L || length(target) != 1L ||
      length(unique(c(id, time, target))) != 3L) stop("id, time and target must be distinct column names.")
  if (!is.character(predictors) || !length(predictors) || anyDuplicated(predictors))
    stop("predictors must be unique column names.")
  cols <- c(id, time, target, predictors)
  if (!all(cols %in% names(data))) stop("Missing columns: ", paste(setdiff(cols, names(data)), collapse = ", "))
  if (any(c(id, time, target) %in% predictors)) stop("Identifiers, time and target cannot be predictors.")
  bad <- grepl("explained_by|dystopia|residual|whisker|happiness_rank|ladder_score|life_ladder|standard_error|upperwhisker|lowerwhisker|^rank$|^score$",
                .clean(predictors))
  if (any(bad)) stop("Target-derived or ranking columns prohibited: ", paste(predictors[bad], collapse = ", "))
  if (anyNA(data[c(id, time)]) || any(!nzchar(trimws(as.character(data[[id]])))))
    stop("Missing or empty panel keys.")
  if (!is.numeric(data[[time]]) || any(!is.finite(data[[time]])) ||
      any(data[[time]] != floor(data[[time]]))) stop("time must contain finite integer years.")
  if (anyDuplicated(data[c(id, time)])) stop("Duplicate country-year keys.")
  if (!is.numeric(data[[target]]) || any(!is.finite(data[[target]])))
    stop("Target must be numeric and fully observed; handle missing targets explicitly before auditing.")
  .numeric_matrix(data, predictors)
  invisible(list(rows = nrow(data), units = length(unique(data[[id]])),
    years = sort(unique(data[[time]])), missing_by_predictor = colSums(is.na(data[predictors]))))
}

split_panel <- function(data, id = "country", time = "year",
                        mode = c("country", "future"), train_fraction = 0.75,
                        cutoff = NULL, seed = 42) {
  mode <- match.arg(mode)
  .scalar(train_fraction, "train_fraction", 0.05, 0.95)
  if (!all(c(id, time) %in% names(data)) || anyNA(data[c(id, time)]))
    stop("Valid id and time columns are required.")
  if (mode == "country") {
    units <- unique(as.character(data[[id]]))
    if (length(units) < 2L) stop("Need at least two countries.")
    n <- max(1L, min(length(units) - 1L, floor(length(units) * train_fraction)))
    selected <- .seeded(seed, units[sample.int(length(units), n)])
    train <- which(as.character(data[[id]]) %in% selected)
    test <- setdiff(seq_len(nrow(data)), train)
  } else {
    years <- sort(unique(data[[time]]))
    if (!is.numeric(years) || length(years) < 2L) stop("Future mode requires multiple numeric years.")
    if (is.null(cutoff)) cutoff <- years[max(1L, min(length(years)-1L, floor(length(years)*train_fraction)))]
    .scalar(cutoff, "cutoff", min(years), max(years))
    train <- which(data[[time]] <= cutoff)
    known <- unique(data[[id]][train])
    test <- which(data[[time]] > cutoff & data[[id]] %in% known)
  }
  if (length(train) < 3L || !length(test)) stop("Insufficient train/test rows after partitioning.")
  list(train = train, test = test,
    excluded = setdiff(seq_len(nrow(data)), c(train, test)), mode = mode, cutoff = cutoff,
    seed = seed)
}

simulate_panel <- function(n_countries = 40, years = 2010:2023, seed = 42) {
  .scalar(n_countries, "n_countries", 4, 100000, TRUE)
  if (!is.numeric(years) || !length(years) || any(!is.finite(years)) ||
      any(years != floor(years)) || anyDuplicated(years)) stop("years must be unique finite integers.")
  .seeded(seed, {
    d <- expand.grid(year = sort(years), country = sprintf("SIM_%03d", seq_len(n_countries)),
                     KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    n <- nrow(d)
    z <- rep(stats::rnorm(n_countries), each = length(years))
    d$log_gdp_per_capita <- 9 + 0.6*z + stats::rnorm(n, 0, .3)
    d$social_support <- stats::plogis(1 + .4*z + stats::rnorm(n, 0, .4))
    d$healthy_life_expectancy <- 61 + 5*z + stats::rnorm(n, 0, 2)
    d$freedom_to_make_life_choices <- stats::plogis(.6 + stats::rnorm(n, 0, .6))
    d$generosity <- stats::rnorm(n, 0, .2)
    d$perceptions_of_corruption <- stats::plogis(.7 - .3*z + stats::rnorm(n, 0, .4))
    d$life_ladder <- 1 + .25*d$log_gdp_per_capita + 1.3*d$social_support +
      .025*d$healthy_life_expectancy + .7*d$freedom_to_make_life_choices +
      .2*d$generosity - .6*d$perceptions_of_corruption + stats::rnorm(n, 0, .25)
    attr(d, "provenance") <- list(data_type = "SIMULATED: not Kaggle observations",
      seed = seed, generating_equation = "1 + .25*gdp + 1.3*support + .025*health + .7*freedom + .2*generosity - .6*corruption + N(0,.25^2)")
    d
  })
}
