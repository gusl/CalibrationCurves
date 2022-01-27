# CalibrationCurves

This is a project to add statistical analyses related to probability
calibration curves and forecaster performance more broadly. This repo
focuses on binary questions.

**Status:** We already have isotonic (a.k.a. monotonic) binary regression (`cgam`), with bootstrapping
to produce approximate confidence regions.

**Future work:** Produce Bayesian intervals with Stan.

## Confidence Intervals via Monotonic Binary Regression + Bootstrap

The isotonic regression model:

For each observation **i**, we have the forecaster's probabilistic
guess <img
src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;X_i\in%20[0,1]">
 and the eventual binary outcome <img
src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;Y_i\in%20\{0,1\}">.

The model is:

<img
src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;Y_i%20\sim%20Bernoulli(g(X_i))">,
where **g** is a non-decreasing function. Under the hood `cgam` is
presumably using isotonic splines, but we don't need to be concerned
with this.

Our bootstrap confidence intervals (CIs) can use one of several
methods:
- `cgam`'s built-in CIs, which do not enforce monotonicity and in fact
  tend to be extremely wide near the X endpoints 0 and 1.
- empirical quantiles of the bootstrap at each X level.
-- which may or may not be smoothed, e.g. with augmentation standing
in as a "prior". Note that smoothing does not guarantee quantiles will
be monotonic, since the endpoints tend to have smaller sample sizes.
