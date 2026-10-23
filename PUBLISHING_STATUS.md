# Development distribution status

This repository distributes scoreAuditR 0.2.0 development source, documentation,
validation tests, study scripts, simulated examples and derived study CSVs.

The maintainer contact in DESCRIPTION is dimassyahputra@unesa.ac.id.
The corresponding author is Dimas Novian Aditia Syahputra. The manuscript author
order is Dimas Novian Aditia Syahputra, Dodik Arwin Dermawan and Septian Rahman Hakim.
Author affiliations, correspondence details, ORCID, funding and conflict-of-interest
declarations are provided in the separate manuscript title page.
No CRAN publication or journal acceptance is claimed.

Core numerical code matches the source tested on R 4.6.1 Windows. Four test scripts
passed following a clean installation on 23 October 2026. See study/retry_validation.txt.
The later repository packaging adds URLs, documentation and reproduction materials.
The archived tar.gz preserves the previously tested package snapshot.

From study/, download the separately licensed version 1 Kaggle data with
`python download_pinned_dataset.py` (requires kagglehub), verify dataset_checksums.csv,
and run `Rscript reproduce.R path/to/World-happiness-report-updated_2024.csv`.

This study involved no recruitment of human participants, direct contact with respondents, interventions, or collection of new human-participant data. All empirical data were obtained exclusively from the publicly available World Happiness Report country-year dataset distributed through Kaggle and were analyzed as country-level aggregate indicators. No identifiable individual-level information was accessed or collected. The ordinal-response datasets used for simulations and software verification were generated computationally and did not represent newly recruited participants.

Raw Kaggle data are not redistributed. MIT licensing applies to software code;
third-party data remain subject to the source terms. Cross-platform execution and
interactive browser testing have not been verified.
