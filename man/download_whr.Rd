\name{download_whr}
\alias{download_whr}
\title{Download the specified Kaggle dataset archive}
\description{Download the specified Kaggle dataset archive. See the installed README and methodology guide for interpretation limits.}
\usage{
download_whr(directory = "whr_data", overwrite = FALSE)
}
\arguments{
\item{directory}{Destination directory for downloads or analysis exports.}
\item{overwrite}{Whether existing named output files may be replaced.}
}
\value{Paths to extracted CSV files. Also records archive checksum and download timestamp. Manual download may be required by Kaggle.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
