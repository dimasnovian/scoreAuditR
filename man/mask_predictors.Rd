\name{mask_predictors}
\alias{mask_predictors}
\title{Introduce structured MCAR predictor missingness}
\description{Introduce structured MCAR predictor missingness. See the installed README and methodology guide for interpretation limits.}
\usage{
mask_predictors(data, predictors, rate = 0.2,
                            pattern = c("cells", "indicator_block", "country_gap"),
                            id = "country", time = "year", block_size = min(2L, length(predictors)),
                            gap_length = 3L, seed = 42)
}
\arguments{
\item{data}{A data frame with unique unit-year keys and numeric predictors.}
\item{predictors}{Unique numeric predictor column names; exclude identifiers and target-derived variables.}
\item{rate}{Desired fraction of originally observed predictor cells to mask.}
\item{pattern}{MCAR pattern geometry: cells, indicator_block or country_gap.}
\item{id}{Name of the country or unit identifier column.}
\item{time}{Name of the integer year column.}
\item{block_size}{Number of adjacent predictor columns in each row-level indicator block.}
\item{gap_length}{Number of genuine consecutive years in each country gap.}
\item{seed}{Nonnegative integer random seed. Random state is restored after sampling.}
}
\value{A list containing data, artificial mask, original_missing mask and achieved-rate metadata.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
