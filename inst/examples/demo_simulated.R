library(scoreAuditR)
d <- simulate_panel()
p <- c("log_gdp_per_capita", "social_support", "healthy_life_expectancy",
       "freedom_to_make_life_choices", "generosity", "perceptions_of_corruption")
a <- audit_panel(d, p, rates = c(0, .1, .3), repetitions = 3,
                 split = "future", cutoff = 2019)
print(a)
export_audit(a, "SIMULATED_demo_results")
