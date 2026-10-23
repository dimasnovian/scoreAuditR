# Development distribution status

This repository distributes scoreAuditR 0.2.0 development source, documentation,
validation tests, study scripts, simulated examples and derived study CSVs.

The maintainer email in DESCRIPTION remains an explicit placeholder. Confirm the
appropriate author contact before a final scholarly software release. The final
manuscript author order, affiliations and declarations also require author input.
No CRAN publication or journal acceptance is claimed.

Core numerical code matches the source tested on R 4.6.1 Windows. Four test scripts
passed following a clean installation on 23 October 2026. See study/retry_validation.txt.
The later repository packaging adds URLs, documentation and reproduction materials.
The archived tar.gz preserves the previously tested package snapshot.

From study/, download the separately licensed version 1 Kaggle data with
`python download_pinned_dataset.py` (requires kagglehub), verify dataset_checksums.csv,
and run `Rscript reproduce.R path/to/World-happiness-report-updated_2024.csv`.

Raw Kaggle data are not redistributed. MIT licensing applies to software code;
third-party data remain subject to the source terms. Cross-platform execution and
interactive browser testing have not been verified.
