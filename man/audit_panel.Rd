\name{audit_panel}
\alias{audit_panel}
\title{Audit paired prediction and explanation stability}
\description{Audit paired prediction and explanation stability. See the installed README and methodology guide for interpretation limits.}
\usage{
audit_panel(data, predictors, id = "country", time = "year", target = "life_ladder",
                       split = c("country", "future"), cutoff = NULL,
                       rates = c(0.1, 0.3), patterns = c("cells", "indicator_block", "country_gap"),
                       methods = c("median", "mean"), repetitions = 5L,
                       train_fraction = 0.75, lambda = 1, block_size = min(2L, length(predictors)),
                       gap_length = 3L, top_k = min(3L, length(predictors)), seed = 42,
                       keep_details = TRUE)
}
\arguments{
\item{data}{A data frame with unique unit-year keys and numeric predictors.}
\item{predictors}{Unique numeric predictor column names; exclude identifiers and target-derived variables.}
\item{id}{Name of the country or unit identifier column.}
\item{time}{Name of the integer year column.}
\item{target}{Name of the fully observed numeric target column.}
\item{split}{Evaluation task, country or future. A single partition is fixed throughout the audit.}
\item{cutoff}{Last training year for future mode. NULL selects a cutoff from the observed years.}
\item{rates}{Vector of desired observed-cell missingness fractions between zero and one.}
\item{patterns}{Vector of MCAR pattern geometries to evaluate.}
\item{methods}{Imputation comparators, median and/or mean.}
\item{repetitions}{Number of independent masks for each scenario.}
\item{train_fraction}{Fraction used to choose training countries or the default time cutoff.}
\item{lambda}{Positive ridge penalty on coefficients of standardized training covariates.}
\item{block_size}{Number of adjacent predictor columns in each row-level indicator block.}
\item{gap_length}{Number of genuine consecutive years in each country gap.}
\item{top_k}{Number of global top features used for overlap comparisons.}
\item{seed}{Nonnegative integer random seed. Random state is restored after sampling.}
\item{keep_details}{Whether to retain full masks, per-row predictions and per-feature importance tables. FALSE reduces memory for large replications. Condition metrics remain available.}
}
\value{A score_audit object containing condition results, Monte Carlo summaries, masks, predictions, global importance, fitted references, partition and configuration.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
\examples{
d <- simulate_panel(8, 2010:2015)
p <- c("log_gdp_per_capita", "social_support")
a <- audit_panel(d, p, patterns = "cells", rates = c(0, .2), repetitions = 2)
a$results
}
