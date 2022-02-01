library(cgam)

Last <- function(v) v[length(v)]

AugmentData <- function(d, n.orig=1) {
  ## n.orig: number of times raw data counts, typically 1 or 2
  ## pseudo.data (4 points) counts only once
  pseudo.data <- data.frame(guess=c(0,0,1,1), outcome=c(0,1,0,1))
  raws <- data.frame()
  for (i in 1:n.orig) {
    raws <- rbind(raws, d)
  }
  return(rbind(raws, pseudo.data))
}

# Simulate --------------

N <- 500
ps <- sort(rbeta(N, shape1=1, shape2=1))

## So that 0 -> 0.01, 1 -> 0.99
RoundGuess <- function(p) (floor(98*p) + 1)/100
DistortUnderconf <- function(x) 0.5 + 4*(x - 0.5)^3
CubeRoot <- function(x) sign(x) * abs(x)^(1/3)
DistortOverconf <- function(x) 0.5 + CubeRoot((x - 0.5) / 4)

{ XX <- seq(0, 1, .01)
par(mfrow=c(1,2))
YY <- DistortUnderconf(XX)
plot(XX, YY, type='l')
YY <- DistortOverconf(XX)
plot(XX, YY, type='l')
guess <- RoundGuess(ps)
outcome <- rbinom(N, 1, prob=ps)
rm(XX)}

## Distort guess to model forecaster "personality". Pick one of these:
guess
## guess <- DistortUnderconf(guess) ## This one works
## guess <- DistortOverconf(guess) ## This one breaks the bootstrap

## ToDo:
## Add command-line argument --input_csv
## data <- read.csv(...)
data <- data.frame(guess=guess, outcome=outcome)
raw.data <- data
dev.off()
with(raw.data, plot(guess, outcome))

data <- AugmentData(data)
RoundPercent <- function(p) round(p*100)/100

# Bootstrap CIs ---------------------------------------------------------------

full.XX <- seq(0.0, 1.00, 0.01)
full.XX <- sapply(full.XX, RoundPercent)

Bootstrap <- function(data, K = 20, add.pseudodata = TRUE) {
  ## data:
  ## K: number of bootstrap samples
  ## add.pseudodata: 
  preds <- matrix(NA, nrow=K, ncol=101)
  if (add.pseudodata) {
    data <- AugmentData(data)
  }
  for (k in 1:K) {
    cat(k, " ")
    boot.N <- ifelse(add.pseudodata, N + 4, N) ## Bootstrap sample size
    indices <- sample(boot.N, replace = TRUE)
    d <- data[indices, ]
    fit <- cgam(outcome ~ incr(guess), data = d, family = binomial())
    XX <- seq(max(0.01, min(d$guess)), min(0.99, max(d$guess)), 0.01) ## range gets bigger with pseudodata
    XX <- RoundPercent(XX)
    full.XX <- RoundPercent(full.XX)
    tryCatch({
      pred <- predict(fit, data.frame(guess=XX))$fit ## Extrapolation not allowed
      preds[k, match(XX, full.XX)] <- pred   ## Replace some of the NAs
    }, error=function(e) {print(e); browser()})
    if (min(filter(pred, c(1,-1)), na.rm=TRUE) < 0) {
      cat("ERROR: Detected non-isotonic fit:  k =", k) ## Just in case
    }
  }
  return(preds)
}

preds <- Bootstrap(data, K=200, add.pseudodata = TRUE)

XX.sample.size <- apply(preds, 2, function(v) sum(!is.na(v)))
XX.sample.size

## Use 15 as the minimum acceptable threshold for quantile estimation
## ToDo: This threshold should be a function of the quantile
good.indices <- which(XX.sample.size >= 15)
XX <- full.XX[good.indices]



ComputeCIs <- function(coverage, use.builtin=TRUE, adjust=FALSE, use.beta=FALSE) {
  ## use.builtin: cgam's own method for generating confidence regions.
  ## adjust: Hack using the beta model to ensure CI isn't empty
  ## use.beta: use a Beta model to generate CIs at each X level.
  q1 <- (1 - coverage)/2
  qs <- c(q1, 1 - q1)
  ## Built-in
  if (use.builtin) {
    fit <- cgam(outcome ~ incr(guess), data=mle.data, family=binomial())
    pred <- predict(fit, data.frame(guess=mle.XX),
                    interval='confidence', level=coverage)
    l <- pred$lower
    u <- pred$upper
  } else { ## Bootstrap CIs
    XX.sample.size <- apply(preds, 2, function(v) sum(!is.na(v)))
    good.indices <- which(XX.sample.size >= 15)
    num.present <- apply(preds[, good.indices], 2, function(v) sum(!is.na(v)))
    cis <- apply(preds[, good.indices], 2, 
                 function(v) quantile(v, ## augment with 0 and 1?
                                      qs, na.rm=TRUE))
    l <- cis[1,]
    u <- cis[2,]
  }
  ##if (adjust) {
  ## Idea:
  ## For all points (on the extremities?), compute the worst Beta quantile
  ## Should be weighted by bootstrap samples K
  #################
  ## Idea: use moment-matching for Beta family?
  ## Problem: E[log(x)] = -infinity
  ## Match mean and variance instead? Then it becomes hard to solve analytically.
  ## }
  return(data.frame(X = full.XX[good.indices], l = l, u = u))
}


# Make Plots ---------------------------------------------------------------------

PlotCIs <- function (XX, levels=c(.8, .95), extend.polygon=TRUE) {
  for (level in levels){
    cis <- ComputeCIs(level, use.builtin = use.builtin, adjust=adjust, use.beta=use.beta)
    if (extend.polygon){
      with(cis, polygon(c(0, XX, 1, 1, rev(XX), 0),
                        c(0, l, Last(l), 1, rev(u), u[1]),
                        col=col, border=NA))
    } else {
      with(cis, polygon(c(XX, rev(XX)),
                        c(l, rev(u)),
                        col=col, border=NA))
    }
  }
}

## MLE using raw data
mle.data <- raw.data
mle.XX <- with(mle.data, seq(min(guess),max(guess), 0.01))


par(mar=rep(5,4))
with(raw.data,
     plot(guess, -0.12 + 1.14 * outcome + 0.1 * runif(N), asp=1,
          xlab="Guess", ylab="Empirical Frequency", col='#00000080', pch=16))
abline(h=c(0,1), col="black")
adjust <- FALSE; use.builtin <- FALSE; use.beta <- FALSE; ci.method <- paste0("Bootstrap with pseudo-data"); col <- "#00000030"
PlotCIs(XX, extend.polygon=FALSE)
## Built-in method
adjust <- FALSE; use.builtin <- TRUE; use.beta <- FALSE; ci.method <- "Built-in confidence intervals (cgam)"; col <- "#FF000030"
PlotCIs(mle.XX, extend.polygon=FALSE)

## Diagonal line and title
abline(0,1, lty=2)
title(paste0(ci.method
             ,"\nConfidence levels: 80%, 95%\n"
), cex=0.8)





# Plot MLE ---------------------------------------------------------------------



red <- "#AA0000A0"
purple <- "#AA00FFA0"


fit <- cgam(outcome ~ incr(guess), data=mle.data, family=binomial())
pred <- predict(fit, data.frame(guess=mle.XX))
predfit <- pred$fit
points(mle.XX, predfit, type='l', col=red)

## MLE using augmented data
mle.data <- AugmentData(raw.data, n.orig = 9)
mle.XX <- with(mle.data, seq(min(guess),max(guess), 0.01))
fit <- cgam(outcome ~ incr(guess), data=mle.data, family=binomial())
pred <- predict(fit, data.frame(guess=mle.XX))
predfit <- pred$fit
points(mle.XX, predfit, type='l', col=purple, lty=1)
legend(0,1,legend=c("Raw est.","Smoothed est."),lty = 1,
       col=c(red, purple), cex=0.5, border=NA)

