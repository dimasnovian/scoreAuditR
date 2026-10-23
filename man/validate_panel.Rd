\name{validate_panel}
\alias{validate_panel}
\title{Validate numeric panel input}
\description{Validate numeric panel input. See the installed README and methodology guide for interpretation limits.}
\usage{
validate_panel(data, id = "country", time = "year", target = "life_ladder",
                           predictors)
}
\arguments{
\item{data}{A data frame with unique unit-year keys and numeric predictors.}
\item{id}{Name of the country or unit identifier column.}
\item{time}{Name of the integer year column.}
\item{target}{Name of the fully observed numeric target column.}
\item{predictors}{Unique numeric predictor column names; exclude identifiers and target-derived variables.}
}
\value{Invisibly returns dimensions, years and natural missingness counts; invalid input raises an error.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
