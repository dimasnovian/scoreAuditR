library(scoreAuditR)
expect_error <- function(expr) stopifnot(inherits(tryCatch({force(expr); NULL}, error = identity), "error"))
d <- simulate_panel(12, 2010:2019, 11)
p <- c("log_gdp_per_capita", "social_support", "healthy_life_expectancy",
       "freedom_to_make_life_choices", "generosity", "perceptions_of_corruption")
validate_panel(d, predictors = p)
expect_error(validate_panel(rbind(d, d[1, ]), predictors = p))
bad <- d; bad$life_ladder[1] <- NA_real_
expect_error(validate_panel(bad, predictors = p))
bad <- d; bad$explained_by_log_gdp <- 1
expect_error(validate_panel(bad, predictors = c(p, "explained_by_log_gdp")))
set.seed(79); old <- .Random.seed
invisible(simulate_panel(seed = 1))
stopifnot(identical(old, .Random.seed))
s <- split_panel(d, seed = 11)
stopifnot(!any(d$country[s$train] %in% d$country[s$test]))
f <- split_panel(d, mode = "future", cutoff = 2016)
stopifnot(max(d$year[f$train]) < min(d$year[f$test]))
m0 <- mask_predictors(d, p, rate = 0)
stopifnot(identical(m0$data, d), !any(m0$mask))
m <- mask_predictors(d, p, rate = .2, seed = 12)
stopifnot(identical(m, mask_predictors(d, p, .2, seed = 12)))
stopifnot(sum(m$mask) == round(.2*nrow(d)*length(p)))
x <- as.matrix(d[p]); xm <- as.matrix(m$data[p])
stopifnot(all(x[!m$mask] == xm[!m$mask]), all(is.na(xm[m$mask])))
dn <- d; dn[[p[1]]][1] <- NA_real_
mn <- mask_predictors(dn, p, .2)
stopifnot(!mn$mask[1,1], mn$original_missing[1,1])
g <- mask_predictors(d, p, .1, "country_gap", gap_length = 2)
stopifnot(all(rowSums(g$mask) %in% c(0L, length(p))))
fit <- fit_panel_model(d[s$train, ], "life_ladder", p)
original_fill <- fit$fill
changed <- d[s$test, ]; changed[[p[1]]] <- NA_real_
pred <- predict_panel(fit, changed)
stopifnot(all(is.finite(pred)), identical(original_fill, fit$fill))
ex <- explain_linear(fit, changed, d[s$train, p])
stopifnot(max(abs(ex$prediction-pred)) < 1e-10)
expect_error(fit_panel_model(transform(d, social_support = NA_real_), "life_ladder", p))
a <- audit_panel(d, p, rates = 0, patterns = "cells", repetitions = 2)
stopifnot(all(a$results$status == "ok"), max(abs(a$results$delta_rmse)) < 1e-12,
          max(abs(a$results$attribution_mae)) < 1e-12)
a1 <- audit_panel(d, p, rates = .2, patterns = c("cells", "country_gap"), repetitions = 2)
a2 <- audit_panel(d, p, rates = .2, patterns = c("cells", "country_gap"), repetitions = 2)
stopifnot(identical(a1, a2))
failed <- audit_panel(d, p, rates = 1, patterns = "cells", repetitions = 1)
stopifnot(all(failed$results$status == "failed"), all(failed$summary$n_failed == 1))
tmp <- tempfile(); dir.create(tmp)
export_audit(a1, tmp)
stopifnot(file.exists(file.path(tmp,"audit.rds")), identical(readRDS(file.path(tmp,"audit.rds")), a1))
expect_error(export_audit(a1, tmp))
csv <- tempfile(fileext = ".csv")
raw <- d; names(raw)[names(raw) == "country"] <- "Country name"
names(raw)[names(raw) == "life_ladder"] <- "Life Ladder"
names(raw)[names(raw) == "healthy_life_expectancy"] <- "Healthy life expectancy at birth"
utils::write.csv(raw, csv, row.names = FALSE)
imported <- read_whr(csv)
stopifnot(all(c("country", "year", "life_ladder", p) %in% names(imported)))
cat("All invariant tests passed.\n")
