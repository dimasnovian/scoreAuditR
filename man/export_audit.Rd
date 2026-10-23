\name{export_audit}
\alias{export_audit}
\title{Export tables, masks and reproducibility metadata}
\description{Export tables, masks and reproducibility metadata. See the installed README and methodology guide for interpretation limits.}
\usage{
export_audit(audit, directory, overwrite = FALSE)
}
\arguments{
\item{audit}{A score_audit object returned by audit_panel.}
\item{directory}{Destination directory for downloads or analysis exports.}
\item{overwrite}{Whether existing named output files may be replaced.}
}
\value{Invisibly returns the normalized output directory. Writes four CSV tables, the full RDS audit, session information and readable configuration.}
\details{The package is a development release. MCAR pattern geometry is separate from a missingness mechanism. Naturally missing predictors are retained. Training parameters are never estimated from test rows. See README.md for the full statistical protocol and validation status.}
