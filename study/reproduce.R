# Reproduce the study from the extracted release directory.
# Usage: Rscript reproduce.R path/to/World-happiness-report-updated_2024.csv
# The original Kaggle file is not redistributed with this release.
args <- commandArgs(trailingOnly=TRUE)
if (!length(args) || !file.exists(args[1])) stop("Supply the actual annual WHR CSV as the first argument.")
root <- normalizePath(getwd(),winslash="/")
lib <- file.path(root,"r-library"); dir.create(lib,showWarnings=FALSE)
.libPaths(c(lib,.libPaths()))
archive <- file.path(root,"scoreAuditR_0.2.0.tar.gz")
if (!requireNamespace("scoreAuditR",quietly=TRUE) ||
    as.character(utils::packageVersion("scoreAuditR")) != "0.2.0")
  install.packages(archive,repos=NULL,type="source",lib=lib)
library(scoreAuditR)
output <- file.path(root,"reproduced_results"); dir.create(output,showWarnings=FALSE)
replicates <- vector("list",100)
for(r in 1:100) {
  sim <- simulate_measurement(500,4,10,seed=900000+r)
  a <- audit_measurement(sim,rates=c(0,.1,.2,.3),seed=10000+100*r)
  a$results$replication <- r; replicates[[r]] <- a$results
  if(r%%5==0) {
    saveRDS(replicates,file.path(output,"measurement_checkpoint.rds"))
    cat("Generated replicate",r,"of 100\n")
  }
}
utils::write.csv(do.call(rbind,replicates),file.path(output,"measurement_results.csv"),row.names=FALSE)
d <- read_whr(args[1],source_url="https://www.kaggle.com/datasets/jainaru/world-happiness-report-2024-yearly-updated")
excluded <- sum(!is.finite(d$life_ladder))
cat("Excluded missing targets:",excluded,"\n")
d <- d[is.finite(d$life_ladder),,drop=FALSE]
p <- c("log_gdp_per_capita","social_support","healthy_life_expectancy",
  "freedom_to_make_life_choices","generosity","perceptions_of_corruption")
for(task in c("country","future")) {
  a <- audit_panel(d,p,split=task,cutoff=if(task=="future") 2018 else NULL,
    rates=c(0,.1,.2,.3),repetitions=100,seed=7301,keep_details=FALSE)
  export_audit(a,file.path(output,paste0("WHR_",task)),overwrite=TRUE)
}
writeLines(utils::capture.output(utils::sessionInfo()),file.path(output,"sessionInfo.txt"))
cat("Reproduction complete. Compare CSVs, not runtime timestamps.\n")
