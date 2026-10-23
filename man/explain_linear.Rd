\name{explain_linear}
\alias{explain_linear}
\title{Explain an imputed linear predictor using a fixed background}
\description{Explain an imputed linear predictor using a fixed background. See the installed README and methodology guide for interpretation limits.}
\usage{
explain_linear(model, newdata, background)
}
\arguments{
\item{model}{A fitted panel_audit_model returned by fit_panel_model.}
\item{newdata}{New rows containing numeric predictor columns.}
\item{background}{Fixed, fully observed numeric background data frame with the same predictor columns.}
}
\value{A list of exact interventional linear Shapley values, base value, reconstructed predictions and background mean.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
