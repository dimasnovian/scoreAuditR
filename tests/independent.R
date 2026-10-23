library(scoreAuditR)
d <- simulate_panel(8,2010:2015,seed=66)
p <- c("social_support","generosity","log_gdp_per_capita")
f <- fit_panel_model(d,"life_ladder",p,lambda=1)
x <- as.matrix(d[p]); ctr <- colMeans(x); sc <- apply(x,2,sd)
z <- sweep(sweep(x,2,ctr,"-"),2,sc,"/")
# Independent QR fit of an augmented penalized least-squares problem.
design <- cbind(1,z)
augmented <- rbind(design,cbind(0,diag(sqrt(1),length(p))))
qrfit <- lm.fit(augmented,c(d$life_ladder,rep(0,length(p))))
reference <- drop(design %*% qrfit$coefficients)
stopifnot(max(abs(reference-predict_panel(f,d))) < 1e-10)
# Independent exhaustive interventional Shapley coalition sum, using predict().
instance <- d[1,,drop=FALSE]
phi <- numeric(length(p)); names(phi) <- p
value <- function(selected) {
  background <- d
  for(j in selected) background[[p[j]]] <- instance[[p[j]]]
  mean(predict_panel(f,background))
}
for(j in seq_along(p)) {
  others <- setdiff(seq_along(p),j)
  for(bits in 0:(2^length(others)-1)) {
    selected <- others[as.logical(intToBits(bits)[seq_along(others)])]
    size <- length(selected)
    weight <- factorial(size)*factorial(length(p)-size-1)/factorial(length(p))
    phi[j] <- phi[j]+weight*(value(c(selected,j))-value(selected))
  }
}
stopifnot(max(abs(phi-explain_linear(f,instance,d)$values[1,])) < 1e-10)
cat("Independent QR ridge and exhaustive Shapley checks passed.\n")
