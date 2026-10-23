library(scoreAuditR)
simulated <- simulate_measurement(100,3,10,seed=42)
audit <- audit_measurement(simulated,rates=c(0,.1,.3),keep_scores=TRUE)
audit$results
# Interpret coverage jointly with errors; latent-theta and item-mean errors
# are on different scales. These are simulated units, not real participants.
