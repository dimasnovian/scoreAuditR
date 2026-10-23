mask_predictors <- function(data, predictors, rate = 0.2,
                            pattern = c("cells", "indicator_block", "country_gap"),
                            id = "country", time = "year", block_size = min(2L, length(predictors)),
                            gap_length = 3L, seed = 42) {
  pattern <- match.arg(pattern)
  .scalar(rate, "rate", 0, 1)
  .scalar(block_size, "block_size", 1, length(predictors), TRUE)
  .scalar(gap_length, "gap_length", 1, .Machine$integer.max, TRUE)
  if (!length(predictors) || anyDuplicated(predictors)) stop("Specify unique predictors.")
  x <- .numeric_matrix(data, predictors)
  eligible <- !is.na(x)
  n_observed <- sum(eligible)
  if (!n_observed) stop("No observed predictor cells to mask.")
  target <- round(rate * n_observed)
  mask <- matrix(FALSE, nrow(x), ncol(x), dimnames = dimnames(x))
  .seeded(seed, {
    if (target > 0L && pattern == "cells") {
      idx <- which(eligible)
      mask[idx[sample.int(length(idx), target)]] <- TRUE
    } else if (target > 0L && pattern == "indicator_block") {
      # Whole row-level adjacent indicator blocks; final block is never truncated.
      starts <- seq_len(max(1L, ncol(x) - block_size + 1L))
      candidates <- expand.grid(row = seq_len(nrow(x)), start = starts)
      ord <- sample.int(nrow(candidates))
      for (k in ord) {
        i <- candidates$row[k]
        j <- seq.int(candidates$start[k], length.out = block_size)
        new <- eligible[i, j] & !mask[i, j]
        if (any(new)) mask[i, j[new]] <- TRUE
        if (sum(mask) >= target) break
      }
    } else if (target > 0L) {
      if (!all(c(id, time) %in% names(data)) || !is.numeric(data[[time]]) ||
          anyNA(data[c(id, time)]) || anyDuplicated(data[c(id, time)]))
        stop("Country-gap masking requires unique nonmissing country-year keys.")
      groups <- split(seq_len(nrow(data)), as.character(data[[id]]))
      candidates <- list()
      for (ii in groups) {
        ii <- ii[order(data[[time]][ii])]
        if (length(ii) < gap_length) next
        for (s in seq_len(length(ii)-gap_length+1L)) {
          rows <- ii[seq.int(s, length.out = gap_length)]
          if (gap_length == 1L || all(diff(data[[time]][rows]) == 1L))
            candidates[[length(candidates)+1L]] <- rows
        }
      }
      if (!length(candidates)) stop("No consecutive-year gaps of requested length exist.")
      for (k in sample.int(length(candidates))) {
        rows <- candidates[[k]]
        # Missing all predictors throughout this genuine consecutive-year window.
        mask[rows, ] <- eligible[rows, ]
        if (sum(mask) >= target) break
      }
    }
    out <- data
    for (j in seq_along(predictors)) out[[predictors[j]]][mask[, j]] <- NA_real_
    list(data = out, mask = mask, original_missing = is.na(x),
      metadata = list(pattern = pattern, mechanism = "MCAR design (pattern selection independent of values)",
        target_rate = rate, actual_rate_observed = sum(mask)/n_observed,
        actual_rate_all = sum(mask)/length(x), original_missing_rate = mean(is.na(x)),
        total_missing_rate = mean(is.na(as.matrix(out[predictors]))),
        masked_cells = sum(mask), observed_cells = n_observed, seed = seed,
        target_reached = sum(mask) >= target, block_size = block_size, gap_length = gap_length))
  })
}
