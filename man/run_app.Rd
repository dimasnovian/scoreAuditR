\name{run_app}
\alias{run_app}
\title{Launch the optional English Shiny interface}
\description{Launch the optional English Shiny interface. See the installed README and methodology guide for interpretation limits.}
\usage{
run_app(...)
}
\arguments{
\item{...}{Additional arguments passed to shiny::runApp.}
}
\value{The result of shiny::runApp. Requires the optional shiny package.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
