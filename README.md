# scoreAuditR 0.2.0

Audit score, change, prediction and explanation sensitivity under structured
missingness. The primary application is repeated ordinal measurement; the
World Happiness Report country-year panel is a secondary example.

## Install

```r
install.packages("remotes")
remotes::install_github("dimasnovian/scoreAuditR", dependencies=FALSE)
library(scoreAuditR)
s <- simulate_measurement(100,3,10,seed=42)
a <- audit_measurement(s,rates=c(0,.1,.3))
a$results
```

Requires R >= 4.1.0; execution was tested on R 4.6.1 Windows only. The core uses
standard R packages and has no compiled extension. Optional Shiny provides the
English interface via `run_app()` and is installed separately.

## What the package does

- `simulate_measurement()` generates five-category graded responses with
  AR(1) latent occasions. Oracle values are stored separately from item data.
- `mask_items()` distinguishes geometry (cells, item blocks, whole occasions)
  from MCAR and observed-covariate MAR fixed-count selection designs.
- `fit_scoring()` and `score_new()` separate training-based item-mode imputation
  from evaluation and support available-item means and known-calibration EAP.
- `evaluate_scores()` reports scoring and change coverage beside errors.
- `audit_measurement()` executes paired measurement conditions on a unit-disjoint
  split. Operational item-mean and generated-theta RMSE scales stay separate.
- `read_whr()`, `audit_panel()` and `export_audit()` support the secondary
  country-year prediction workflow with training-only imputers, ridge regression
  and exact interventional linear Shapley attributions on imputed covariates.

Known EAP uses generating item parameters, not empirical calibration. All
measurement methods leave empty occasions unscored. Low error among retained
occasions does not imply high coverage or complete recovery. MAR uses only an
always-observed auxiliary covariate; it is not inferred from the dataset.
Domain blocks are item groups within a unidimensional generator, not evidence
of multidimensional validity. See `inst/doc/manual.md` and function help.

## Verified study

The accompanying study contains 100 independently generated measurement datasets,
7,200 measurement condition-method-replicate rows, and 4,800 WHR evaluations.
The actual annual WHR file contains 2,137 observations from 152 countries,
2005-2023. Country-disjoint and chronological tasks are reported separately.
Naturally missing predictor cells are retained and distinct from artificial masks.

The four test scripts cover invariants, independent numerical comparisons,
measurement scoring and Shiny server/script parity. Independent comparisons use
numerical EAP integration, augmented QR ridge regression and exhaustive Shapley
coalitions. The Windows R CMD check reported Status: OK; see VALIDATION_STATUS.md. Check options omit the
PDF reference manual/vignettes and allow unavailable optional Suggests; direct
Shiny server tests were also executed successfully. Browser clicking and
cross-platform execution were not tested.

The study was not externally preregistered. Measurement MCSE spans independent
generated datasets; WHR MCSE spans artificial masks on one fixed dataset/split.
Neither constitutes a population sampling confidence interval.

## Exact real-data source

https://www.kaggle.com/datasets/jainaru/world-happiness-report-2024-yearly-updated

The studied resource is version 1. Use the accompanying pinned kagglehub script
or supply the original annual CSV to `reproduce.R`. Raw Kaggle data are not
redistributed. Dataset rights are distinct from the MIT software license.
Do not use single-report rankings, Explained by components, whiskers, ranks or
score-derived residuals as predictors of the target. Chronological evaluation
uses contemporaneous indicators; it is not an advance forecast from lagged inputs.

## Current limits and release administration

MNAR, empirical item calibration, ordinal multiple imputation, nonlinear models,
generic checkpoint resumption and graphical cancellation are not implemented.
Sensitivity diagnostics do not establish construct validity, invariance or causality.
The package name is not reserved and no CRAN publication is claimed. The author
email in DESCRIPTION is a documented placeholder that must be replaced before
a final scholarly release. This repository is a development distribution. Multiple manuscript authors have been requested, but their final
order and corresponding contact have not yet been supplied.

Manuscript author identities and declarations require completion separately from
the development software distribution.

## Reproduction files in this repository

See `study/` for the pinned download script, source archive, reproduction script, source checksums and derived study CSVs. Run reproduction from that directory. See `PUBLISHING_STATUS.md` for unresolved publication metadata.

## Software and data links

- Source: https://github.com/dimasnovian/scoreAuditR
- Tested source archive: [study/scoreAuditR_0.2.0.tar.gz](study/scoreAuditR_0.2.0.tar.gz)
- Kaggle: https://www.kaggle.com/datasets/jainaru/world-happiness-report-2024-yearly-updated

To use the optional interface, install Shiny separately with `install.packages("shiny")`, then run `scoreAuditR::run_app()`. Raw Kaggle data are downloaded separately.
