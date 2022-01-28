## Calibrating the calibrator!
## Ironically, calibration curves typically don't come with any probabilistic
## claims.

Last <- function(v) v[length(v)]
library(cgam)

AugmentData <- function(d, n.orig=1) {
  ## n.orig: number of times raw data counts, typically 1 or 2
  ## pseudo.data counts only once
  pseudo.data <- data.frame(guess=c(0,0,1,1), outcome=c(0,1,0,1))
  raws <- data.frame()
  for (i in 1:n.orig) {
    raws <- rbind(raws, d)
  }
  return(rbind(raws, pseudo.data))
}

###############
# Simulate
###############
N <- 30
ps <- sort(rbeta(N, shape1=1, shape2=1))

## So that 0 -> 0.01, 1 -> 0.99
RoundGuess <- function(p) (floor(98*p) + 1)/100
guess <- RoundGuess(ps)
outcome <- rbinom(N, 1, prob=ps)
data <- data.frame(guess=guess, outcome=outcome)
raw.data <- data
data <- AugmentData(data)
RoundPercent <- function(p) round(p*100)/100

# Bootstrap CIs ---------------------------------------------------------------

Bootstrap <- function(data, K = 20, add.pseudodata = TRUE) {
  ## data:
  ## K: number of bootstrap samples
  ## add.pseudodata: 
  preds <- matrix(NA, nrow=K, ncol=101)
  full.XX <- seq(0.0, 1.00, 0.01)
  full.XX <- sapply(full.XX, RoundPercent)
  if (add.pseudodata) {
    data <- AugmentData(data)
  }
  for (k in 1:K) {
    cat(k, " ")
    boot.N <- ifelse(add.pseudodata, N + 4, N) ## Bootstrap sample size
    indices <- sample(boot.N, replace = TRUE)
    d <- data[indices, ]
    fit <- cgam(outcome ~ incr(guess), data = d, family = binomial())
    XX <- seq(min(d$guess), max(d$guess), 0.01) ## range gets bigger with pseudodata
    XX <- RoundPercent(XX)
    full.XX <- RoundPercent(full.XX)
    pred <- predict(fit, data.frame(guess=XX))$fit ## Extrapolation not allowed
    preds[k, match(XX, full.XX)] <- pred   ## Replace some of the NAs
    if (min(filter(pred, c(1,-1)), na.rm=TRUE) < 0) {
      cat("ERROR: Detected non-monotonic fit:  k =", k) ## Just in case
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

## Quantile of a Beta distribution on the less identified side near the endpoints.
## Instead of plugging in data, we enter the 'pred'
BetaQuantile <- function(q, p, XX.sample.size, K) {
  ## Treat the estimates as data. shape1 = 1 + (K - sum(p)), shape2 = 1 + sum(p)
  ## q: desired quantile
  ## p: vector of estimated probabilities
  ## XX.sample.size: bootstrap sample size for each XX
  qbeta(qs,
        shape1 = 1 + (K - XX.sample.size) * p,
        shape2 = 1 + XX.sample.size * p)
}
## Original problem: The empirical CI is sometimes exactly 0 at the tails. We
## could threshold it with a constant defined by the Beta quantile.


ComputeCIs <- function(coverage, use.builtin=TRUE, adjust=FALSE, use.beta=FALSE) {
  ## use.builtin: cgam's own method for generating confidence regions.
  ## adjust: Hack using the beta model to ensure CI isn't empty
  ## use.beta: use a Beta model to generate CIs at each X level.
  q1 <- (1 - coverage)/2
  qs <- c(q1, 1 - q1)
  ## Built-in
  if (use.builtin) {
    fit <- cgam(outcome ~ incr(guess), data=mle.data, family=binomial())
    pred <- predict(fit, data.frame(guess=XX),
                    interval='confidence', level=coverage)
    l <- pred$lower
    u <- pred$upper
  } else { ## Bootstrap CIs
    num.present <- apply(preds[, good.indices], 2, function(v) sum(!is.na(v)))
    cis <- apply(preds[, good.indices], 2, 
                 function(v) quantile(v, ## augment with 0 and 1?
                                      qs, na.rm=TRUE))
    ##
    ## If neither 0 nor 1 is present, then some of the bootstrap samples won't have an opinion there
    ## Lower the sample size, and leading to a higher upper quantile.
    l <- cis[1,]
    u <- cis[2,]
  }
  if (adjust) {
    ## BUG: these vectors (*.thresholds) are backwards
    ## For all points (on the extremities?), compute the worst Beta quantile
    ## Should be weighted by bootstrap samples K
    #################
    ## Idea: use moment-matching for Beta family?
    ## Problem: E[log(x)] = -infinity
    ## Match mean and variance instead? Then it becomes hard to solve analytically.
    upper.thresholds <- sapply(good.indices, 
                               function(i)
                                 qbeta(qs[2], 
                                       shape2 = 1 + mean(1 - preds[, i]),
                                       shape1 = 1 + mean(preds[, i])))
    thresh.at.0 <- min(upper.thresholds, na.rm=TRUE)
    lower.thresholds <- sapply(good.indices,
                               function(i)
                                 qbeta(qs[1], 
                                       shape2 = 1 + mean(1 - preds[, i]),
                                       shape1 = 1 + mean(preds[, i])))
    thresh.at.1 <- max(lower.thresholds, na.rm=TRUE)
    if (use.beta){
      u <- upper.thresholds
      l <- lower.thresholds
    } else {
      u <- ifelse(u < thresh.at.0, thresh.at.0, u)
      l <- ifelse(l > thresh.at.1, thresh.at.1, l)
    }
  }
  return(data.frame(l=l, u=u))
}


# Make Plots ---------------------------------------------------------------------

PlotCIs <- function (levels=c(.8, .95, .98)) {
  for (level in levels){
  cis <- ComputeCIs(level, use.builtin = use.builtin, adjust=adjust, use.beta=use.beta)
  with(cis, polygon(c(0, XX, 1, 1, rev(XX), 0),
                    c(0, l, Last(l), 1, rev(u), u[1]),
                    col=col, border=NA))
  }
}

par(mar=rep(5,4))
with(raw.data,
     plot(guess, -0.12 + 1.14 * outcome + 0.1 * runif(N), asp=1,
          xlab="Guess", ylab="Empirical frequency", col='#00000080', pch=16))
abline(h=c(0,1), col="#00000030")
adjust <- FALSE; use.builtin <- FALSE; use.beta <- FALSE; ci.method <- paste0("Bootstrap with pseudo-data"); col <- "#00000030"
PlotCIs()
adjust <- FALSE; use.builtin <- TRUE; use.beta <- FALSE; ci.method <- "Built-in confidence intervals (cgam)"; col <- "#FF000030"
PlotCIs()


#adjust <- TRUE; use.builtin <- FALSE; use.beta <- TRUE; ci.method <- paste0("Bootstrap with Beta"); col <- "#0000FF30"
#PlotCIs()


legend(0.01,1,legend=c("Built-in","Bootstrap"),lty = 1,
       col=c("red", "black"), cex=0.6, border=NA)
title("Comparison of different CIs methods\n Perfect calibration shown as diagonal")

## Diagonal line and title
abline(0,1, lty=2)
title(paste0(ci.method
             ,"\nConfidence levels: 80%, 95%, 98%\n"
             ), cex=0.8)


# Plot MLE ---------------------------------------------------------------------



red <- "#AA0000A0"
purple <- "#AA00FFA0"


## MLE using raw data
mle.data <- raw.data
mle.XX <- with(mle.data, seq(min(guess),max(guess), 0.01))
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
legend(0,1,legend=c("Raw estimate","Smoothed estimate"),lty = 1,
       col=c(red, purple), cex=0.4, border=NA)
