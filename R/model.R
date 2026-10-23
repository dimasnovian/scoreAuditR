fit_panel_model <- function(train, target, predictors,
                            imputation = c("median", "mean"), lambda = 1) {
  imputation <- match.arg(imputation)
  .scalar(lambda, "lambda", 1e-10, 1e10)
  if (target %in% predictors) stop("Target cannot be a predictor.")
  x <- .numeric_matrix(train, predictors)
  y <- train[[target]]
  if (!is.numeric(y) || length(y) != nrow(x) || any(!is.finite(y)) || nrow(x) < 3L)
    stop("Training target must be finite with at least three rows.")
  if (any(colSums(!is.na(x)) == 0L)) stop("All-missing training predictor; cannot estimate imputation.")
  fill <- if (imputation == "median") apply(x, 2, stats::median, na.rm = TRUE) else
    colMeans(x, na.rm = TRUE)
  x <- .fill(x, fill)
  center <- colMeans(x)
  scale <- apply(x, 2, stats::sd)
  scale[!is.finite(scale) | scale == 0] <- 1
  z <- sweep(sweep(x, 2, center, "-"), 2, scale, "/")
  # Objective: sum of squared residuals + lambda * sum(standardized beta^2).
  beta_z <- drop(solve(crossprod(z) + diag(lambda, ncol(z)),
                        crossprod(z, y - mean(y))))
  beta <- setNames(beta_z/scale, predictors)
  structure(list(predictors = predictors, target = target, fill = fill,
    coefficients = beta, intercept = mean(y) - sum(center*beta),
    imputation = imputation, lambda = lambda, n_train = nrow(train)), class = "panel_audit_model")
}

predict_panel <- function(model, newdata) {
  if (!inherits(model, "panel_audit_model")) stop("Expected a fitted panel model.")
  x <- .fill(.numeric_matrix(newdata, model$predictors), model$fill)
  drop(model$intercept + x %*% model$coefficients)
}

explain_linear <- function(model, newdata, background) {
  # Exact interventional Shapley values of the fitted linear predictor, on
  # already imputed covariates. This is not conditional or raw-input SHAP.
  if (!inherits(model, "panel_audit_model")) stop("Expected a fitted panel model.")
  x <- .fill(.numeric_matrix(newdata, model$predictors), model$fill)
  b <- .numeric_matrix(background, model$predictors)
  if (!nrow(b) || anyNA(b)) stop("Supply a fixed, fully observed background matrix.")
  mu <- colMeans(b)
  phi <- sweep(sweep(x, 2, mu, "-"), 2, model$coefficients, "*")
  base <- model$intercept + sum(mu*model$coefficients)
  list(values = phi, base_value = base, prediction = base + rowSums(phi),
    background_mean = mu,
    definition = "exact interventional linear Shapley values on imputed covariates; fixed raw-scale background")
}
