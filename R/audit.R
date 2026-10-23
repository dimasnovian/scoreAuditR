audit_panel <- function(data, predictors, id = "country", time = "year", target = "life_ladder",
                       split = c("country", "future"), cutoff = NULL,
                       rates = c(0.1, 0.3), patterns = c("cells", "indicator_block", "country_gap"),
                       methods = c("median", "mean"), repetitions = 5L,
                       train_fraction = 0.75, lambda = 1, block_size = min(2L, length(predictors)),
                       gap_length = 3L, top_k = min(3L, length(predictors)), seed = 42,
                       keep_details = TRUE) {
  split <- match.arg(split)
  validation <- validate_panel(data, id, time, target, predictors)
  .scalar(repetitions, "repetitions", 1, 100000, TRUE)
  .scalar(top_k, "top_k", 1, length(predictors), TRUE)
  .scalar(seed, "seed", 0, 1000000000, TRUE)
  if (!is.logical(keep_details) || length(keep_details) != 1L || is.na(keep_details)) stop("keep_details must be TRUE or FALSE.")
  if (!is.numeric(rates) || !length(rates) || any(!is.finite(rates)) || any(rates < 0 | rates > 1))
    stop("rates must be numeric between 0 and 1.")
  if (!length(patterns) || !all(patterns %in% c("cells", "indicator_block", "country_gap")))
    stop("Unknown missingness pattern.")
  if (!length(methods) || !all(methods %in% c("median", "mean"))) stop("Unknown imputation method.")
  partition <- split_panel(data, id, time, split, train_fraction, cutoff, seed)
  train <- data[partition$train, , drop = FALSE]
  test <- data[partition$test, , drop = FALSE]
  # Fixed background: original training predictors with training median fills.
  ref <- fit_panel_model(train, target, predictors, "median", lambda)
  background <- as.data.frame(.fill(.numeric_matrix(train, predictors), ref$fill))
  names(background) <- predictors
  baseline <- list()
  for (method in unique(methods)) {
    model <- fit_panel_model(train, target, predictors, method, lambda)
    pred <- predict_panel(model, test)
    baseline[[method]] <- list(model = model, prediction = pred,
      metrics = .metrics(test[[target]], pred),
      explanation = explain_linear(model, test, background))
  }
  configurations <- expand.grid(repetition = seq_len(repetitions), pattern = unique(patterns),
    rate = unique(rates), stringsAsFactors = FALSE)
  results <- predictions <- importance <- list()
  masks <- list()
  for (a in seq_len(nrow(configurations))) {
    cfg <- configurations[a, ]
    mask_seed <- as.integer(seed + 2L*a)
    # Partitions are masked independently: a temporal gap never spans the split.
    mt <- tryCatch(mask_predictors(train, predictors, cfg$rate, cfg$pattern,
      id, time, block_size, gap_length, mask_seed), error = identity)
    me <- tryCatch(mask_predictors(test, predictors, cfg$rate, cfg$pattern,
      id, time, block_size, gap_length, mask_seed+1L), error = identity)
    if (keep_details && !inherits(mt, "error") && !inherits(me, "error"))
      masks[[as.character(a)]] <- list(train = mt$mask, test = me$mask,
        original_train_missing = mt$original_missing, original_test_missing = me$original_missing,
        train_metadata = mt$metadata, test_metadata = me$metadata)
    for (method in unique(methods)) {
      header <- data.frame(config_id = a, repetition = cfg$repetition, pattern = cfg$pattern,
        target_rate = cfg$rate, method = method, mask_seed_train = mask_seed,
        mask_seed_test = mask_seed+1L, stringsAsFactors = FALSE)
      res <- tryCatch({
        if (inherits(mt, "error")) stop(conditionMessage(mt))
        if (inherits(me, "error")) stop(conditionMessage(me))
        model <- fit_panel_model(mt$data, target, predictors, method, lambda)
        pred <- predict_panel(model, me$data)
        ex <- explain_linear(model, me$data, background)
        base <- baseline[[method]]
        m <- .metrics(test[[target]], pred)
        gi <- colMeans(abs(ex$values))
        bi <- colMeans(abs(base$explanation$values))
        top <- function(x) order(-x, names(x))[seq_len(top_k)]
        paired <- data.frame(row_index = partition$test, country = as.character(test[[id]]),
          year = test[[time]], observed = test[[target]], baseline = base$prediction,
          predicted = pred, stringsAsFactors = FALSE)
        imp <- data.frame(feature = predictors, baseline_mean_abs_phi = bi,
          mean_abs_phi = gi, stringsAsFactors = FALSE, row.names = NULL)
        if (keep_details) {
          predictions[[length(predictions)+1L]] <- cbind(header[rep(1L,nrow(paired)), ], paired)
          importance[[length(importance)+1L]] <- cbind(header[rep(1L,nrow(imp)), ], imp)
        }
        cbind(header, data.frame(status = "ok", error = "",
          actual_rate_train = mt$metadata$actual_rate_observed,
          actual_rate_test = me$metadata$actual_rate_observed,
          target_reached_train = mt$metadata$target_reached,
          target_reached_test = me$metadata$target_reached,
          n_test = nrow(test), mae = unname(m["mae"]), rmse = unname(m["rmse"]),
          bias = unname(m["bias"]), rank_correlation = unname(m["rank_correlation"]),
          delta_mae = unname(m["mae"]-base$metrics["mae"]),
          delta_rmse = unname(m["rmse"]-base$metrics["rmse"]),
          importance_rank_correlation = .safe_cor(bi, gi),
          top_k_overlap = length(intersect(top(gi), top(bi)))/top_k,
          attribution_mae = mean(abs(ex$values-base$explanation$values)),
          prediction_drift = mean(abs(pred-base$prediction)), stringsAsFactors = FALSE))
      }, error = function(e) {
        cbind(header, data.frame(status = "failed", error = conditionMessage(e),
          actual_rate_train = NA_real_, actual_rate_test = NA_real_,
          target_reached_train = NA, target_reached_test = NA,
          n_test = nrow(test), mae = NA_real_, rmse = NA_real_, bias = NA_real_,
          rank_correlation = NA_real_, delta_mae = NA_real_, delta_rmse = NA_real_,
          importance_rank_correlation = NA_real_, top_k_overlap = NA_real_,
          attribution_mae = NA_real_, prediction_drift = NA_real_, stringsAsFactors = FALSE))
      })
      results[[length(results)+1L]] <- res
    }
  }
  results <- do.call(rbind, results)
  groups <- base::split(seq_len(nrow(results)), interaction(results$pattern, results$target_rate,
    results$method, drop = TRUE))
  metric_names <- c("mae", "rmse", "delta_mae", "delta_rmse", "importance_rank_correlation",
    "top_k_overlap", "attribution_mae", "prediction_drift", "actual_rate_train", "actual_rate_test")
  summary <- do.call(rbind, lapply(groups, function(ii) {
    z <- results[ii, ]
    out <- z[1, c("pattern", "target_rate", "method"), drop = FALSE]
    out$n_success <- sum(z$status == "ok")
    out$n_failed <- sum(z$status != "ok")
    for (metric in metric_names) {
      v <- z[[metric]][is.finite(z[[metric]])]
      out[[paste0(metric,"_mean")]] <- if (length(v)) mean(v) else NA_real_
      out[[paste0(metric,"_mcse")]] <- if (length(v) > 1) stats::sd(v)/sqrt(length(v)) else NA_real_
      out[[paste0(metric,"_n_finite")]] <- length(v)
    }
    out
  }))
  structure(list(results = results, summary = summary, baseline = baseline,
    predictions = if (length(predictions)) do.call(rbind, predictions) else data.frame(),
    importance = if (length(importance)) do.call(rbind, importance) else data.frame(),
    masks = masks, partition = partition, validation = validation,
    configuration = list(predictors = predictors, id = id, time = time, target = target,
      split = split, cutoff = partition$cutoff, rates = rates, patterns = patterns,
      methods = methods, repetitions = repetitions, train_fraction = train_fraction,
      lambda = lambda, block_size = block_size, gap_length = gap_length,
      top_k = top_k, seed = seed, mechanism = "MCAR only",
      provenance = attr(data, "provenance"),
      reference = "Original data with training-only imputation of naturally missing predictors",
      explanation = "Exact interventional linear SHAP on imputed covariates; fixed training background",
      uncertainty = "Monte Carlo standard errors across independent masks conditional on one fixed partition and dataset",
      keep_details = keep_details, package_version = as.character(utils::packageVersion("scoreAuditR")))), class = "score_audit")
}

print.score_audit <- function(x, ...) {
  cat("scoreAuditR: structured missingness audit\n")
  cat("Reference: original data with training-only imputation\n")
  cat("Successful:", sum(x$results$status == "ok"), " Failed:", sum(x$results$status != "ok"), "\n")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

export_audit <- function(audit, directory, overwrite = FALSE) {
  if (!inherits(audit, "score_audit")) stop("Expected a score_audit object.")
  if (!is.character(directory) || length(directory) != 1L || !nzchar(directory)) stop("Specify an output directory.")
  filenames <- c("results.csv", "summary.csv", "predictions.csv", "importance.csv",
    "audit.rds", "sessionInfo.txt", "configuration.txt")
  if (!overwrite && any(file.exists(file.path(directory, filenames))))
    stop("Output exists. Choose a new directory or overwrite = TRUE.")
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  for (name in c("results", "summary", "predictions", "importance"))
    utils::write.csv(audit[[name]], file.path(directory, paste0(name, ".csv")), row.names = FALSE)
  saveRDS(audit, file.path(directory, "audit.rds"))
  writeLines(utils::capture.output(utils::sessionInfo()), file.path(directory, "sessionInfo.txt"))
  writeLines(utils::capture.output(utils::str(audit$configuration)), file.path(directory, "configuration.txt"))
  invisible(normalizePath(directory))
}
