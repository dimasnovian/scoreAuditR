library(scoreAuditR)
# Download manually from the exact dataset page or try download_whr().
# The importer reads actual headers rather than assuming fixed column positions.
path <- "whr_data/World-happiness-report-updated_2024.csv"
if (!file.exists(path)) path <- file.choose()
d <- read_whr(path, source_url =
  "https://www.kaggle.com/datasets/jainaru/world-happiness-report-2024-yearly-updated")
p <- c("log_gdp_per_capita", "social_support", "healthy_life_expectancy",
       "freedom_to_make_life_choices", "generosity", "perceptions_of_corruption")
stopifnot(all(p %in% names(d)))
# Missing targets are explicitly excluded; naturally missing predictors are retained.
cat("Rows excluded due to unavailable target:", sum(!is.finite(d$life_ladder)), "\n")
d <- d[is.finite(d$life_ladder), , drop = FALSE]
validate_panel(d, predictors = p)
# Pilot, not a final publication experiment. Inspect failures and achieved rates.
a <- audit_panel(d, p, split = "country", rates = c(.1, .2, .3), repetitions = 10)
export_audit(a, "WHR_country_pilot")
if (length(unique(d$year)) > 1L) {
  b <- audit_panel(d, p, split = "future", rates = c(.1, .2, .3), repetitions = 10)
  export_audit(b, "WHR_future_pilot")
}
