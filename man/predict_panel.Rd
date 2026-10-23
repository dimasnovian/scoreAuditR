\name{predict_panel}
\alias{predict_panel}
\title{Predict with frozen training preprocessing}
\description{Predict with frozen training preprocessing. See the installed README and methodology guide for interpretation limits.}
\usage{
predict_panel(model, newdata)
}
\arguments{
\item{model}{A fitted panel_audit_model returned by fit_panel_model.}
\item{newdata}{New rows containing numeric predictor columns.}
}
\value{A numeric prediction vector.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
