library(scoreAuditR)
if (requireNamespace("shiny",quietly=TRUE)) {
  env <- new.env(parent=globalenv())
  sys.source(system.file("shiny","app.R",package="scoreAuditR"),envir=env)
  predictors <- c("log_gdp_per_capita","social_support","healthy_life_expectancy",
    "freedom_to_make_life_choices","generosity","perceptions_of_corruption")
  shiny::testServer(env$server, {
    session$setInputs(source="sim",predictors=predictors,split="country",rate=.1,
      patterns="cells",reps=2,seed=42,run=0)
    session$setInputs(run=1)
    actual <- result()
    expected <- audit_panel(simulate_panel(seed=42),predictors,split="country",rates=.1,
      patterns="cells",repetitions=2,seed=42)
    stopifnot(identical(actual$results,expected$results))
    session$setInputs(m_units=30,m_pattern="domain",m_mechanism="MAR",m_rate=.3,run_measurement=0)
    session$setInputs(run_measurement=1)
    expected_m <- audit_measurement(simulate_measurement(30,seed=42),rates=.3,
      patterns="domain",mechanisms="MAR",seed=42)
    stopifnot(identical(measurement_result()$results,expected_m$results))
  })
  cat("Shiny panel and measurement server parity checks passed.\n")
}
