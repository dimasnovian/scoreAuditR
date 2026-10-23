validate_measurement <- function(data, items, id = "unit_id", time = "wave", categories = 5L) {
  if (!is.data.frame(data) || !nrow(data) || !all(c(id, time, items) %in% names(data)))
    stop("Supply response rows, item columns and unit-wave keys.")
  if (!length(items) || anyDuplicated(items) || any(c(id, time) %in% items)) stop("Invalid item names.")
  .scalar(categories, "categories", 2, 20, TRUE)
  if (anyNA(data[c(id, time)]) || anyDuplicated(data[c(id, time)])) stop("Unit-wave keys must be observed and unique.")
  if (!is.numeric(data[[time]]) || any(!is.finite(data[[time]]))) stop("wave must be numeric.")
  x <- .numeric_matrix(data, items)
  observed <- x[!is.na(x)]
  if (any(observed != floor(observed) | observed < 1 | observed > categories))
    stop("Observed responses must be integer categories from 1 to categories.")
  invisible(TRUE)
}

simulate_measurement <- function(n_units = 300L, n_waves = 3L, n_items = 10L,
                                 rho = 0.7, trend = 0.15, seed = 42) {
  .scalar(n_units, "n_units", 4, 100000, TRUE)
  .scalar(n_waves, "n_waves", 2, 50, TRUE)
  .scalar(n_items, "n_items", 4, 100, TRUE)
  .scalar(rho, "rho", -0.99, 0.99)
  .scalar(trend, "trend", -5, 5)
  .seeded(seed, {
    theta <- matrix(0, n_units, n_waves)
    theta[,1] <- stats::rnorm(n_units)
    for (w in 2:n_waves) theta[,w] <- rho*(theta[,w-1] - trend*(w-2)) +
      stats::rnorm(n_units, 0, sqrt(1-rho^2)) + trend*(w-1)
    z <- as.vector(t(theta))
    d <- data.frame(unit_id = rep(sprintf("SIM_%04d", seq_len(n_units)), each = n_waves),
      wave = rep(seq_len(n_waves), n_units), stringsAsFactors = FALSE)
    # This covariate remains observed and is the sole driver of MAR selection.
    d$auxiliary <- 0.5*z + stats::rnorm(length(z), 0, 1)
    items <- sprintf("item_%02d", seq_len(n_items))
    a <- seq(0.9, 1.8, length.out = n_items)
    b <- outer(seq(-0.25, 0.25, length.out = n_items), c(-1.5, -0.5, 0.5, 1.5), "+")
    for (j in seq_len(n_items)) {
      # Graded response P(Y >= k+1 | theta) = logistic(a * (theta - b_k)).
      exceed <- stats::plogis(a[j]*outer(z, b[j,], "-"))
      u <- stats::runif(length(z))
      d[[items[j]]] <- 1L + rowSums(u < exceed)
    }
    calibration <- list(items = items, discrimination = a, thresholds = b,
      categories = 5L, origin = "known simulation parameters, not estimated from held-out responses")
    oracle <- data.frame(unit_id = d$unit_id, wave = d$wave, theta = z)
    attr(d, "provenance") <- list(data_type = "SIMULATED ordinal responses, no human participants",
      seed = seed, rho = rho, trend = trend, model = "unidimensional logistic graded response model")
    list(data = d, oracle = oracle, calibration = calibration, items = items,
      domains = stats::setNames(ceiling(seq_len(n_items)/(n_items/2)), items), seed = seed)
  })
}

mask_items <- function(data, items, rate = 0.2, pattern = c("cells", "domain", "wave"),
                       mechanism = c("MCAR", "MAR"), domains = NULL,
                       auxiliary = "auxiliary", seed = 42) {
  pattern <- match.arg(pattern); mechanism <- match.arg(mechanism)
  .scalar(rate, "rate", 0, 1)
  validate_measurement(data, items)
  x <- as.matrix(data[items]); eligible <- !is.na(x)
  if (!sum(eligible)) stop("No observed item cells.")
  mask <- matrix(FALSE, nrow(x), ncol(x), dimnames = dimnames(x))
  target <- round(rate*sum(eligible))
  weights <- rep(1, nrow(x))
  if (mechanism == "MAR") {
    if (!auxiliary %in% names(data) || !is.numeric(data[[auxiliary]]) || any(!is.finite(data[[auxiliary]])))
      stop("MAR requires a fully observed numeric auxiliary covariate.")
    z <- data[[auxiliary]]
    scale <- stats::sd(z)
    if (scale > 0) weights <- exp(pmax(-20, pmin(20, .8*(z-mean(z))/scale)))
  }
  .seeded(seed, {
    if (target > 0 && pattern == "cells") {
      idx <- which(eligible)
      probs <- rep(weights, ncol(x))[idx]
      mask[idx[sample.int(length(idx), target, prob = probs)]] <- TRUE
    } else if (target > 0) {
      if (pattern == "wave") domains <- rep(1L, length(items))
      if (is.null(domains)) domains <- ceiling(seq_along(items)/(length(items)/2))
      if (length(domains) != length(items) || anyNA(domains)) stop("domains must assign every item to a block.")
      if (!is.null(names(domains))) domains <- domains[items]
      if (anyNA(domains)) stop("Named domains must contain every item.")
      blocks <- split(seq_along(items), domains)
      candidates <- expand.grid(row = seq_len(nrow(x)), block = seq_along(blocks))
      ord <- sample.int(nrow(candidates), prob = weights[candidates$row])
      for (k in ord) {
        i <- candidates$row[k]; j <- blocks[[candidates$block[k]]]
        mask[i,j] <- eligible[i,j]
        if (sum(mask) >= target) break
      }
    }
    out <- data
    for (j in seq_along(items)) out[[items[j]]][mask[,j]] <- NA_integer_
    list(data = out, mask = mask, original_missing = is.na(x),
      metadata = list(pattern = pattern, mechanism = mechanism, target_rate = rate,
        actual_rate = sum(mask)/sum(eligible), masked_cells = sum(mask),
        seed = seed, selection = "fixed-count sampling without replacement; whole blocks are not truncated",
        mar_driver = if (mechanism == "MAR") auxiliary else NULL))
  })
}

fit_scoring <- function(train, items, method = c("available_mean", "item_mode", "known_eap"),
                        min_fraction = 0.5, calibration = NULL, grid = seq(-6,6,length.out = 121)) {
  method <- match.arg(method)
  .scalar(min_fraction, "min_fraction", 0, 1)
  validate_measurement(train, items)
  fill <- NULL
  if (method == "item_mode") fill <- vapply(train[items], function(x) {
    counts <- tabulate(x[!is.na(x)], nbins = 5)
    if (!sum(counts)) stop("An item has no observed training responses.")
    which.max(counts) # category ties choose the lowest category
  }, numeric(1))
  if (method == "known_eap") {
    if (is.null(calibration) || !identical(calibration$items, items) ||
        length(calibration$discrimination) != length(items) ||
        any(!is.finite(calibration$discrimination)) || any(calibration$discrimination <= 0) ||
        !is.matrix(calibration$thresholds) || nrow(calibration$thresholds) != length(items) ||
        ncol(calibration$thresholds) != 4 || any(!is.finite(calibration$thresholds)) ||
        any(apply(calibration$thresholds, 1, function(x) any(diff(x) <= 0))))
      stop("known_eap requires a matching valid five-category calibration.")
    if (!is.numeric(grid) || length(grid) < 21 || any(!is.finite(grid)) ||
        any(diff(grid) <= 0) || max(abs(diff(grid)-diff(grid)[1])) > 1e-8)
      stop("EAP grid must contain at least 21 equally spaced finite increasing points.")
  }
  structure(list(items = items, method = method, min_fraction = min_fraction,
    fill = fill, calibration = calibration, grid = grid), class = "measurement_scoring")
}

score_new <- function(model, data) {
  if (!inherits(model, "measurement_scoring")) stop("Expected a measurement_scoring model.")
  validate_measurement(data, model$items)
  x <- as.matrix(data[model$items]); observed <- rowSums(!is.na(x))
  if (model$method == "available_mean") {
    score <- rowMeans(x, na.rm = TRUE)
    score[observed < max(1, ceiling(model$min_fraction*ncol(x)))] <- NA_real_
  } else if (model$method == "item_mode") {
    score <- rowMeans(.fill(x, model$fill))
    score[observed == 0] <- NA_real_
  } else {
    grid <- model$grid
    ll <- matrix(stats::dnorm(grid, log = TRUE), nrow(x), length(grid), byrow = TRUE)
    for (j in seq_len(ncol(x))) {
      a <- model$calibration$discrimination[j]
      b <- model$calibration$thresholds[j,]
      ge <- stats::plogis(a*outer(grid,b,"-"))
      probabilities <- cbind(1,ge) - cbind(ge,0)
      for (k in 1:5) {
        rows <- which(!is.na(x[,j]) & x[,j] == k)
        if (length(rows)) ll[rows,] <- sweep(ll[rows,,drop=FALSE], 2,
          log(pmax(probabilities[,k], .Machine$double.xmin)), "+")
      }
    }
    ll <- ll - apply(ll, 1, max)
    posterior <- exp(ll)
    score <- drop(posterior %*% grid)/rowSums(posterior)
    score[observed == 0] <- NA_real_ # no prior-only scores for an empty occasion
  }
  score[!is.finite(score)] <- NA_real_
  score
}

evaluate_scores <- function(data, estimate, reference, baseline = NULL,
                            id = "unit_id", time = "wave") {
  n <- nrow(data)
  if (length(estimate) != n || length(reference) != n || any(!is.finite(reference)))
    stop("Scores must align with rows and reference must be fully observed.")
  ok <- is.finite(estimate)
  err <- estimate[ok]-reference[ok]
  ord <- order(data[[id]], data[[time]])
  first <- head(ord, -1); second <- tail(ord,-1)
  pair <- data[[id]][first] == data[[id]][second] & data[[time]][second]-data[[time]][first] == 1
  first <- first[pair]; second <- second[pair]
  paired <- is.finite(estimate[first]) & is.finite(estimate[second])
  change_error <- (estimate[second[paired]]-estimate[first[paired]]) -
    (reference[second[paired]]-reference[first[paired]])
  out <- c(coverage = mean(ok), n_scored = sum(ok), bias = if (length(err)) mean(err) else NA_real_,
    rmse = if (length(err)) sqrt(mean(err^2)) else NA_real_,
    rank_correlation = .safe_cor(estimate,reference),
    change_coverage = if (length(paired)) mean(paired) else NA_real_,
    change_bias = if (length(change_error)) mean(change_error) else NA_real_,
    change_rmse = if (length(change_error)) sqrt(mean(change_error^2)) else NA_real_)
  if (!is.null(baseline)) {
    if (length(baseline) != n) stop("baseline length mismatch.")
    common <- ok & is.finite(baseline)
    out <- c(out, delta_rmse_on_scorable_rows = if (any(common))
      sqrt(mean((estimate[common]-reference[common])^2))-
      sqrt(mean((baseline[common]-reference[common])^2)) else NA_real_)
  }
  out
}
