\name{fit_panel_model}
\alias{fit_panel_model}
\title{Fit training-only imputation and ridge regression}
\description{Fit training-only imputation and ridge regression. See the installed README and methodology guide for interpretation limits.}
\usage{
fit_panel_model(train, target, predictors,
                            imputation = c("median", "mean"), lambda = 1)
}
\arguments{
\item{train}{Training data frame. Imputation and model parameters are fitted here only.}
\item{target}{Name of the fully observed numeric target column.}
\item{predictors}{Unique numeric predictor column names; exclude identifiers and target-derived variables.}
\item{imputation}{Training-based mean or median imputation.}
\item{lambda}{Positive ridge penalty on coefficients of standardized training covariates.}
}
\value{A panel_audit_model with frozen imputation values, raw-scale coefficients and intercept.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
