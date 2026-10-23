.seeded <- function(seed, code) {
  if (length(seed) != 1L || !is.numeric(seed) || !is.finite(seed) ||
      seed < 0 || seed > .Machine$integer.max || seed != floor(seed))
    stop("seed must be a nonnegative integer within the R integer range.")
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had) assign(".Random.seed", old, envir = .GlobalEnv) else
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv))
  set.seed(as.integer(seed))
  force(code)
}

.scalar <- function(x, name, lo, hi, integer = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < lo ||
      x > hi || (integer && x != floor(x)))
    stop(name, " must be a finite ", if (integer) "integer " else "number ",
         "between ", lo, " and ", hi, ".")
}

.clean <- function(x) {
  x <- tolower(trimws(sub("^\ufeff", "", x)))
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_|_$", "", x)
}

.safe_cor <- function(a, b) {
  ok <- is.finite(a) & is.finite(b)
  if (sum(ok) < 3L || stats::sd(a[ok]) == 0 || stats::sd(b[ok]) == 0)
    return(NA_real_)
  stats::cor(a[ok], b[ok], method = "spearman")
}

.metrics <- function(y, pred) {
  e <- pred - y
  c(mae = mean(abs(e)), rmse = sqrt(mean(e^2)), bias = mean(e),
    rank_correlation = .safe_cor(y, pred))
}

.numeric_matrix <- function(data, predictors) {
  if (!is.data.frame(data) || !all(predictors %in% names(data)))
    stop("Predictor columns are missing.")
  if (!all(vapply(data[predictors], is.numeric, logical(1))))
    stop("All predictors must be numeric.")
  x <- as.matrix(data[predictors])
  if (any(!is.finite(x) & !is.na(x))) stop("Infinite predictors are not supported.")
  x
}

.fill <- function(x, values) {
  for (j in seq_len(ncol(x))) x[is.na(x[, j]), j] <- values[j]
  x
}
