\name{audit_measurement}
\alias{audit_measurement}
\alias{validate_measurement}
\alias{simulate_measurement}
\alias{mask_items}
\alias{fit_scoring}
\alias{score_new}
\alias{evaluate_scores}
\title{Audit Repeated Ordinal Measurement Scores}
\description{Simulate logistic graded response data, introduce structured MCAR or observed-covariate MAR missingness, score incomplete occasions and evaluate score and change recovery.}
\usage{
validate_measurement(data, items, id = "unit_id", time = "wave", categories = 5L)
simulate_measurement(n_units = 300L, n_waves = 3L, n_items = 10L,
  rho = 0.7, trend = 0.15, seed = 42)
mask_items(data, items, rate = 0.2, pattern = c("cells", "domain", "wave"),
  mechanism = c("MCAR", "MAR"), domains = NULL, auxiliary = "auxiliary", seed = 42)
fit_scoring(train, items, method = c("available_mean", "item_mode", "known_eap"),
  min_fraction = 0.5, calibration = NULL, grid = seq(-6,6,length.out = 121))
score_new(model, data)
evaluate_scores(data, estimate, reference, baseline = NULL,
  id = "unit_id", time = "wave")
audit_measurement(simulation, rates = c(.1,.3),
  patterns = c("cells", "domain", "wave"), mechanisms = c("MCAR", "MAR"),
  methods = c("available_mean", "item_mode", "known_eap"),
  min_fraction = .5, seed = 42, keep_scores = FALSE)
}
\arguments{
\item{data,train}{Ordinal response data frames with unique unit-wave keys. Training and evaluation rows must be separated by unit.}
\item{items}{Unique item column names with observed categories 1 through 5.}
\item{id,time}{Unit and occasion column names.}
\item{categories}{Integer category count for validation; scoring uses five categories.}
\item{n_units,n_waves,n_items}{Simulation dimensions.}
\item{rho}{AR(1) correlation between successive latent occasions.}
\item{trend}{Mean latent change per occasion.}
\item{seed}{Integer sampling seed. Sampling restores the caller random state.}
\item{rate,rates}{Target proportions of originally observed item cells to mask. Whole blocks may overshoot.}
\item{pattern,patterns}{Scattered cells, predefined item-domain blocks, or all items at one unit occasion.}
\item{mechanism,mechanisms}{MCAR or MAR fixed-count designs. MAR selection weights are exp(0.8 times standardized auxiliary), capped for numerical stability.}
\item{domains}{Item-to-block assignments in item order, or a named vector covering every item.}
\item{auxiliary}{Fully observed numeric covariate used exclusively for MAR selection weights.}
\item{method,methods}{Available-item mean, training item-mode imputation or known-calibration EAP scoring.}
\item{min_fraction}{Minimum observed fraction for available-item means. Other methods require at least one observed item.}
\item{calibration}{Known item discrimination and ordered thresholds, with item names matching items. No latent oracle is accepted by a scoring model.}
\item{grid}{Equally spaced quadrature grid for an N(0,1) EAP prior.}
\item{model}{Object returned by fit_scoring.}
\item{estimate,reference,baseline}{Aligned numeric score vectors. Baseline is optional.}
\item{simulation}{Output of simulate_measurement, including separately stored oracle values for evaluation only.}
\item{keep_scores}{Whether to retain per-row evaluation scores.}
}
\value{Simulation returns response data, separate oracle, item calibration and domain assignments. Masking returns masked data, the artificial and original masks, and metadata. fit_scoring returns a measurement_scoring object; score_new returns numeric scores. Evaluation returns coverage, bias, RMSE, rank correlation, consecutive-wave change metrics and optional paired RMSE changes. audit_measurement returns condition results, baseline models, partition, optional per-row scores and configuration. Validation returns TRUE invisibly or raises an error.}
\details{Responses follow P(Y >= k+1 given theta) = logistic(a times (theta-b[k])). The calibration is fixed across waves. Known EAP is a validation benchmark with generating item parameters, not a fitted empirical IRT calibration. Empty occasions are not scored by any method. Mean and mode scores are evaluated on the complete-response mean scale; EAP is evaluated against generated theta. These RMSE scales must not be pooled or compared as though identical. Change evaluation uses consecutive numeric occasions only. The audit uses one country-style unit-disjoint split per simulated dataset. Domain blocks are item groups within a unidimensional generator, not evidence of multidimensional construct validity.}
\examples{
s <- simulate_measurement(20,3,10,seed=5)
a <- audit_measurement(s,rates=c(0,.2),patterns="cells",mechanisms="MCAR")
a$results
}
