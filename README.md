# CalibrationCurves

This is a project to add statistical analyses related to probability
calibration curves and forecaster performance more broadly. This repo
focuses on binary questions.

**Status:** We already have isotonic (a.k.a. non-decreasing) binary
regression (`cgam`), to produce approximate confidence regions (see below).

**Future work:** Produce Bayesian intervals with Stan, using isotonic
splines to enforce shape constraint.

## Confidence Intervals via Isotonic Binary Regression

We now present isotonic binary regression.

For each observation **i**, we have the forecaster's probabilistic
guess <img
src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;X_i\in%20[0,1]">
 and the eventual binary outcome <img
src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;Y_i\in%20\{0,1\}">.

The model is:

<img
src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;Y_i%20\sim%20Bernoulli(g(X_i))">,
where **g** is a non-decreasing function. We don't know what `cgam`
uses under the hood to enforce this shape constraint, but it does work
-- MLE is isotonic.  Unfortunately, isotonicity is not guaranteed for
the CIs.  Our methods likewise don't guarantee that the quantile will be
isotonic as a function of X, but they do improve this significantly.

Our bootstrap confidence intervals (CIs) can use one of several
methods:
- (A) `cgam`'s built-in CIs, which do not have isotonicity and in fact
  tend to be extremely wide near the X endpoints 0 and 1, which is not ideal.
- (B) Empirical quantiles of the bootstrap at each X level.
  - which may or may not be smoothed, e.g. with 4 pseudo-observations
    to serve as a "prior". This is better, but note that it still does
    not guarantee monotonicity, since the endpoints tend to have smaller sample sizes.
