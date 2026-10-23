\name{read_whr}
\alias{read_whr}
\title{Import a World Happiness Report CSV}
\description{Import a World Happiness Report CSV. See the installed README and methodology guide for interpretation limits.}
\usage{
read_whr(path, year = NULL, source_url = NULL)
}
\arguments{
\item{path}{Path to an actual UTF-8 CSV file.}
\item{year}{Explicit report year used only if the file has no year column; NULL requires a year column.}
\item{source_url}{Dataset source URL retained in provenance metadata.}
}
\value{A normalized data frame with file checksum and provenance attributes.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
