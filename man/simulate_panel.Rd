\name{simulate_panel}
\alias{simulate_panel}
\title{Generate a labelled simulated country panel}
\description{Generate a labelled simulated country panel. See the installed README and methodology guide for interpretation limits.}
\usage{
simulate_panel(n_countries = 40, years = 2010:2023, seed = 42)
}
\arguments{
\item{n_countries}{Number of simulated country units, at least four.}
\item{years}{Unique integer years for the simulated panel.}
\item{seed}{Nonnegative integer random seed. Random state is restored after sampling.}
}
\value{A complete data frame labelled SIMULATED in its provenance. It is not actual Kaggle data.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
\examples{
d <- simulate_panel(8, 2010:2015)
head(d)
}
