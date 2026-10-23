audit_measurement <- function(simulation, rates = c(.1,.3),
                               patterns = c("cells", "domain", "wave"),
                               mechanisms = c("MCAR", "MAR"),
                               methods = c("available_mean", "item_mode", "known_eap"),
                               min_fraction = .5, seed = 42, keep_scores = FALSE) {
  required <- c("data", "oracle", "calibration", "items", "domains")
  if (!is.list(simulation) || !all(required %in% names(simulation))) stop("Expected simulate_measurement output.")
  d <- simulation$data; items <- simulation$items
  validate_measurement(d,items)
  if (anyNA(d[items])) stop("Controlled simulation audit requires complete reference responses.")
  if (!identical(d[c("unit_id","wave")], simulation$oracle[c("unit_id","wave")]))
    stop("Oracle keys must align with response rows.")
  if (!length(rates) || any(!is.finite(rates)) || any(rates < 0 | rates > 1)) stop("Invalid rates.")
  if (!length(patterns) || !all(patterns %in% c("cells","domain","wave"))) stop("Invalid patterns.")
  if (!length(mechanisms) || !all(mechanisms %in% c("MCAR","MAR"))) stop("Invalid mechanisms.")
  if (!length(methods) || !all(methods %in% c("available_mean","item_mode","known_eap"))) stop("Invalid methods.")
  partition <- split_panel(d, id="unit_id", time="wave", seed=seed)
  tr <- d[partition$train,,drop=FALSE]; te <- d[partition$test,,drop=FALSE]
  oracle <- simulation$oracle$theta[partition$test]
  reference_mean <- rowMeans(as.matrix(te[items]))
  base <- list()
  for (method in methods) {
    model <- fit_scoring(tr,items,method,min_fraction,simulation$calibration)
    scores <- score_new(model,te)
    reference <- if (method == "known_eap") oracle else reference_mean
    base[[method]] <- list(scores=scores, metrics=evaluate_scores(te,scores,reference), model=model)
  }
  configs <- expand.grid(pattern=patterns,mechanism=mechanisms,rate=rates,stringsAsFactors=FALSE)
  rows <- details <- list()
  for (i in seq_len(nrow(configs))) {
    cfg <- configs[i,]
    train_seed <- seed+2*i; test_seed <- seed+2*i+1L
    mt <- mask_items(tr,items,cfg$rate,cfg$pattern,cfg$mechanism,simulation$domains,seed=train_seed)
    me <- mask_items(te,items,cfg$rate,cfg$pattern,cfg$mechanism,simulation$domains,seed=test_seed)
    for (method in methods) {
      model <- fit_scoring(mt$data,items,method,min_fraction,simulation$calibration)
      estimate <- score_new(model,me$data)
      reference <- if (method == "known_eap") oracle else reference_mean
      evaluated <- evaluate_scores(te,estimate,reference,base[[method]]$scores)
      header <- data.frame(pattern=cfg$pattern,mechanism=cfg$mechanism,target_rate=cfg$rate,
        actual_rate_train=mt$metadata$actual_rate,actual_rate_test=me$metadata$actual_rate,
        method=method,metric=if (method == "known_eap") "latent_theta" else "item_mean_1_to_5",
        baseline_rmse=unname(base[[method]]$metrics["rmse"]),
        seed_train=train_seed,seed_test=test_seed,stringsAsFactors=FALSE)
      rows[[length(rows)+1L]] <- cbind(header,as.data.frame(as.list(evaluated)))
      if (keep_scores) details[[length(details)+1L]] <- cbind(
        header[rep(1L,nrow(te)),],te[c("unit_id","wave")],
        data.frame(estimate=estimate,reference=reference,baseline=base[[method]]$scores,
                   observed_items=rowSums(!is.na(me$data[items]))))
    }
  }
  list(results=do.call(rbind,rows), baseline=base,
    scores=if (length(details)) do.call(rbind,details) else NULL,
    partition=partition, configuration=list(seed=seed,min_fraction=min_fraction,
      calibration="known generating item parameters; not fitted to test data",
      missingness="fixed-count weighted designs; MAR uses only the observed auxiliary covariate",
      eap_prior="N(0,1), quadrature -6 to 6 with 121 points; no cross-wave borrowing",
      provenance=attr(d,"provenance")))
}
