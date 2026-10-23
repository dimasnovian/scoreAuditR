library(scoreAuditR)
expect_error <- function(expr) stopifnot(inherits(tryCatch({force(expr);NULL},error=identity),"error"))
s <- simulate_measurement(30,3,10,seed=231)
stopifnot(!"theta" %in% names(s$data), all(as.matrix(s$data[s$items]) %in% 1:5),
  identical(s,simulate_measurement(30,3,10,seed=231)))
validate_measurement(s$data,s$items)
bad <- s$data; bad$item_01[1] <- 6
expect_error(validate_measurement(bad,s$items))
mm <- mask_items(s$data,s$items,.2,"domain","MAR",s$domains,seed=12)
stopifnot(identical(mm,mask_items(s$data,s$items,.2,"domain","MAR",s$domains,seed=12)))
x <- as.matrix(s$data[s$items]); xm <- as.matrix(mm$data[s$items])
stopifnot(all(x[!mm$mask] == xm[!mm$mask]), all(is.na(xm[mm$mask])),
          identical(s$data$auxiliary,mm$data$auxiliary))
for (method in c("available_mean","item_mode","known_eap")) {
  f <- fit_scoring(s$data,s$items,method,calibration=s$calibration)
  empty <- s$data; empty[s$items] <- NA_integer_
  stopifnot(all(is.na(score_new(f,empty))))
  if (method != "known_eap") stopifnot(max(abs(score_new(f,s$data)-rowMeans(x))) < 1e-12)
}
# One-observed-item EAP agrees with an independent direct numerical calculation.
f <- fit_scoring(s$data,s$items,"known_eap",calibration=s$calibration)
one <- s$data[1,,drop=FALSE]; one[s$items[-1]] <- NA_integer_
k <- one$item_01; a <- s$calibration$discrimination[1]; b <- s$calibration$thresholds[1,]
prob <- function(t) {
  upper <- if (k == 1) 1 else plogis(a*(t-b[k-1]))
  lower <- if (k == 5) 0 else plogis(a*(t-b[k]))
  (upper-lower)*dnorm(t)
}
independent <- integrate(function(t) t*prob(t),-6,6)$value/integrate(prob,-6,6)$value
stopifnot(abs(score_new(f,one)-independent) < 1e-6)
z <- audit_measurement(s,rates=0,patterns="cells",mechanisms="MCAR")
stopifnot(all(z$results$coverage == 1), all(abs(z$results$delta_rmse_on_scorable_rows) < 1e-12))
# Fully missing occasions are reported as zero coverage, not silently prior-filled.
z <- audit_measurement(s,rates=1,patterns="wave",mechanisms="MCAR",
  methods=c("available_mean","known_eap"))
stopifnot(all(z$results$coverage == 0),all(is.na(z$results$rmse)))
# Available mean change is exactly zero-error without masking on its operational metric.
model <- fit_scoring(s$data,s$items,"available_mean")
metrics <- evaluate_scores(s$data,score_new(model,s$data),rowMeans(x))
stopifnot(metrics["rmse"] == 0,metrics["change_rmse"] == 0)
cat("All measurement tests passed.\n")
