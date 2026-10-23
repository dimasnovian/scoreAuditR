# scoreAuditR manual version 0.2.0

The primary workflow evaluates repeated ordinal measurement scores. A secondary
workflow audits numeric country-year prediction and exact linear explanations.
No new participants are recruited by either workflow.

## Measurement example

```r
library(scoreAuditR)
s <- simulate_measurement(n_units=100,n_waves=3,n_items=10,seed=42)
a <- audit_measurement(s,rates=c(0,.1,.3),seed=42)
a$results
```

The graded response simulator returns a response data frame, a separate oracle,
known item calibration, domain assignments and seed. The generator is
unidimensional with AR(1) latent occasions and a configurable trend. Item blocks
are predefined groups, not independent validated constructs. Responses are
five-category integers with positively oriented items.

`mask_items` supports cells, item-domain blocks and entire unit occasions.
MCAR samples without response dependence; MAR samples using fixed-count
weights exp(0.8 times standardized always-observed auxiliary). Block geometry
does not determine the missingness mechanism. Whole final blocks are retained,
so achieved fractions can exceed targets.

`fit_scoring` separates training-based item modes from evaluation scoring.
Available-item means require the specified observed fraction. Mode imputation
uses the lowest category in a tie. Known EAP uses the supplied fixed calibration,
an N(0,1) prior and 121 equally spaced quadrature points from -6 to 6. It is not
an empirical IRT calibration routine. All methods leave fully empty occasions
unscored, even though an EAP prior-only estimate could mathematically be formed.

`evaluate_scores` reports score coverage, bias, RMSE and ranks, together with
consecutive-occasion change coverage and errors. Mean/mode scoring is evaluated
on the complete-response mean scale. Known EAP uses the generated theta scale.
Never pool or directly compare these RMSE values. Scorable-row errors can
favor a method that declines more cases; inspect coverage jointly with error.
No-score occasions and unavailable changes remain explicit.

## Panel example

```r
d <- read_whr("World-happiness-report-updated_2024.csv")
p <- c("log_gdp_per_capita","social_support","healthy_life_expectancy",
       "freedom_to_make_life_choices","generosity","perceptions_of_corruption")
d <- d[is.finite(d$life_ladder),,drop=FALSE]
a <- audit_panel(d,p,split="future",cutoff=2018,repetitions=100,keep_details=FALSE)
export_audit(a,"results")
```

The audit masks training and test predictor partitions independently, fits only
on training rows and compares matched evaluation rows. Country-disjoint and
chronological tasks differ. Chronological prediction uses contemporaneous test
indicators and does not constitute an advance forecast from lagged inputs.
Mean/median imputation and ridge scaling are fitted separately for each masked
training condition. The ridge objective is residual sum of squares plus lambda
times squared standardized coefficients; lambda is not tuned on evaluation data.

Naturally missing cells remain distinct from artificial masks. The reference
handles existing missing predictors through training-only imputation and is not
a complete-data oracle. Linear attributions are exact interventional Shapley
values for imputed covariates, using one fixed raw-scale training background.
They are not conditional, causal or construct-validity diagnostics.

With keep_details=TRUE, masks, row predictions and importance tables are retained.
FALSE retains condition results while reducing memory. Error conditions are
reported explicitly. MCSE across panel masks is conditional on one dataset and
one partition. The repeated measurement study instead generates independent
datasets, so its Monte Carlo variation includes data generation and partitioning.

## Interface and files

Install optional Shiny with install.packages("shiny"), then run run_app().
The interface calls the exported package functions and has a Measurement scoring
tab. Server parity is tested for panel and measurement calculations; this is
not a visual browser interaction test. run_app requires an installed package.

The archive contains interpreted executable R source, help pages, examples,
tests and labelled simulated sample input/output. The study reproduction script
and full benchmark outputs are separate accompanying files. The original Kaggle
data are not redistributed; use the exact studied version and checksum manifest.

MNAR, empirical item calibration, ordinal multiple imputation, a generic resume
engine and graphical cancellation are not implemented. Core minimum declared R
is 4.1.0; execution was tested on R 4.6.1 Windows only. No CRAN publication or
cross-platform test is claimed. Complete author contact metadata before release.
