\name{split_panel}
\alias{split_panel}
\title{Partition countries or years}
\description{Partition countries or years. See the installed README and methodology guide for interpretation limits.}
\usage{
split_panel(data, id = "country", time = "year",
                        mode = c("country", "future"), train_fraction = 0.75,
                        cutoff = NULL, seed = 42)
}
\arguments{
\item{data}{A data frame with unique unit-year keys and numeric predictors.}
\item{id}{Name of the country or unit identifier column.}
\item{time}{Name of the integer year column.}
\item{mode}{Either country-disjoint evaluation or future-period evaluation of known countries.}
\item{train_fraction}{Fraction used to choose training countries or the default time cutoff.}
\item{cutoff}{Last training year for future mode. NULL selects a cutoff from the observed years.}
\item{seed}{Nonnegative integer random seed. Random state is restored after sampling.}
}
\value{A list of train, test and excluded row indices, split mode, cutoff and seed.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
