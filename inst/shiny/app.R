library(shiny)
library(scoreAuditR)

ui <- fluidPage(
  titlePanel("scoreAuditR | Missingness and Explanation Audit"),
  sidebarLayout(sidebarPanel(
    radioButtons("source", "Data source", c("Simulated demonstration" = "sim", "World Happiness CSV" = "csv")),
    fileInput("csv", "Upload annual country-year CSV", accept = ".csv"),
    helpText("Use the annual Life Ladder table. Report-ranking tables are not annual panels."),
    uiOutput("predictors"),
    selectInput("split", "Evaluation task", c("Held-out countries" = "country", "Future years, known countries" = "future")),
    numericInput("rate", "Target missing fraction of observed cells", .2, min = 0, max = 1, step = .05),
    checkboxGroupInput("patterns", "Missingness pattern (MCAR)",
      c("Scattered cells" = "cells", "Indicator block" = "indicator_block", "Consecutive-year country gap" = "country_gap"), selected = "cells"),
    numericInput("reps", "Independent mask repetitions", 5, min = 1, max = 100, step = 1),
    numericInput("seed", "Seed", 42, min = 0, max = 1000000000, step = 1),
    actionButton("run", "Run audit", class = "btn-primary"),
    downloadButton("download", "Download complete audit (RDS)"),
    downloadButton("csvout", "Download results (CSV)")
  ), mainPanel(
    textOutput("data_label"),
    tabsetPanel(tabPanel("Data", tableOutput("preview")),
      tabPanel("Summary", verbatimTextOutput("status"), tableOutput("summary")),
      tabPanel("Prediction", plotOutput("prediction")),
      tabPanel("Feature attribution", plotOutput("importance")),
      tabPanel("Measurement scoring",
        p("SIMULATED ordinal responses. No human participants. Known EAP calibration is a validation benchmark."),
        numericInput("m_units", "Simulated units", 100, min=20, max=1000),
        selectInput("m_pattern", "Missing item pattern", c("cells","domain","wave")),
        selectInput("m_mechanism", "Selection mechanism", c("MCAR","MAR")),
        numericInput("m_rate", "Missing fraction", .3, min=0, max=.8, step=.1),
        actionButton("run_measurement", "Run measurement audit"),
        tableOutput("measurement_summary"),
        p("Mean and mode RMSE use the item-mean scale. EAP RMSE uses latent theta. Empty occasions remain unscored; compare coverage as well as error.")),
      tabPanel("Interpretation", p("Reference: original predictors with training-only imputation of naturally missing cells."),
        p("Exact interventional linear Shapley values explain the ridge predictor on imputed covariates with one fixed training background."),
        p("Rank and attribution stability measure sensitivity, not construct validity or causal effects. MCSE describes repeated masks on this fixed split, not population sampling uncertainty."),
        p("Large gaps can overshoot the target missing fraction; achieved fractions and failures are reported.")))
  )))

server <- function(input, output, session) {
  measurement_result <- eventReactive(input$run_measurement, {
    tryCatch({
      simulated <- simulate_measurement(n_units=input$m_units, seed=42)
      audit_measurement(simulated,rates=input$m_rate,patterns=input$m_pattern,
        mechanisms=input$m_mechanism,seed=42)
    },error=function(e) { showNotification(conditionMessage(e),type="error"); NULL })
  })
  output$measurement_summary <- renderTable({req(measurement_result());
    measurement_result()$results[c("method","metric","coverage","rmse","change_coverage","change_rmse")]},digits=4)
  d <- reactive({
    if (input$source == "sim") return(simulate_panel(seed = 42))
    req(input$csv)
    tryCatch(read_whr(input$csv$datapath, source_url =
      "https://www.kaggle.com/datasets/jainaru/world-happiness-report-2024-yearly-updated"),
      error = function(e) { validate(need(FALSE, conditionMessage(e))) })
  })
  output$data_label <- renderText(if (input$source == "sim")
    "SIMULATED DATA: not Kaggle observations or research results." else "User-uploaded CSV. Verify source and coverage before publication.")
  output$preview <- renderTable(utils::head(d(), 8))
  output$predictors <- renderUI({
    choices <- names(d())[vapply(d(), is.numeric, logical(1))]
    choices <- setdiff(choices, c("year", "life_ladder"))
    preferred <- intersect(c("log_gdp_per_capita", "social_support", "healthy_life_expectancy",
      "freedom_to_make_life_choices", "generosity", "perceptions_of_corruption"), choices)
    checkboxGroupInput("predictors", "Contextual predictors", choices, selected = preferred)
  })
  result <- eventReactive(input$run, {
    req(input$predictors, input$patterns)
    tryCatch(withProgress(message = "Auditing matched scenarios", value = 0, {
      answer <- audit_panel(d(), predictors = input$predictors, split = input$split,
        rates = input$rate, patterns = input$patterns, repetitions = input$reps,
        block_size = min(2L, length(input$predictors)), top_k = min(3L, length(input$predictors)), seed = input$seed)
      incProgress(1)
      answer
    }), error = function(e) { showNotification(conditionMessage(e), type = "error", duration = NULL); NULL })
  })
  output$status <- renderText({ req(result()); paste("Successful scenarios:", sum(result()$results$status == "ok"),
    "| Failed scenarios:", sum(result()$results$status == "failed")) })
  output$summary <- renderTable({ req(result()); result()$summary }, digits = 4)
  output$prediction <- renderPlot({
    req(result(), nrow(result()$predictions) > 0)
    z <- result()$predictions
    z <- z[z$config_id == z$config_id[1] & z$method == z$method[1], ]
    plot(z$observed, z$predicted, xlab = "Observed Life Ladder", ylab = "Predicted score", pch = 19,
      col = "#267a8b", main = "First successful scenario")
    abline(0, 1, lty = 2)
  })
  output$importance <- renderPlot({
    req(result(), nrow(result()$importance) > 0)
    z <- result()$importance
    z <- z[z$config_id == z$config_id[1] & z$method == z$method[1], ]
    par(mar = c(10, 4, 3, 1))
    barplot(rbind(z$baseline_mean_abs_phi, z$mean_abs_phi), beside = TRUE,
      names.arg = z$feature, las = 2, col = c("#64748b", "#267a8b"),
      ylab = "Mean absolute attribution", main = "First successful scenario")
    legend("topright", c("Reference", "Masked"), fill = c("#64748b", "#267a8b"))
  })
  output$download <- downloadHandler(filename = "scoreAuditR_audit.rds", content = function(file) {
    req(result()); saveRDS(result(), file)
  })
  output$csvout <- downloadHandler(filename = "scoreAuditR_results.csv", content = function(file) {
    req(result()); utils::write.csv(result()$results, file, row.names = FALSE)
  })
}
shinyApp(ui, server)
