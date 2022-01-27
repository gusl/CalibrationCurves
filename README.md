# CalibrationCurves

This is a project to add statistical analyses related to probability
calibration curves and forecaster performance more broadly. This repo
focuses on binary questions.

**Status:** We already have isotonic (a.k.a. monotonic) binary regression (`cgam`), with bootstrapping
to produce approximate confidence regions.

**Future work:** Produce Bayesian intervals with Stan.

## Confidence Intervals via Monotonic Binary Regression + Bootstrap

The isotonic regression model:

For each observation **i**, there's the forecaster's probabilistic
guess `X_i` in [0,1] and the eventual binary outcome `Y_i` in {0, 1}.

The model is:

<img
src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;Y_i%20\sim%20Bernoulli(g(X_i))">,
where **g** is a non-decreasing function. Under the hood `cgam` is
presumably using isotonic splines, but we don't need to be concerned
with this.


Our bootstrap confidence intervals (CIs) are based on empirical
quantiles of the bootstrap at each X level.

If we simply bootstrap, we miss out
smoothing


<img src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;\int_0^\infty%20f^\theta(x)%20dx">

<img src="https://latex.codecogs.com/png.image?\dpi{110}&space;\bg_black&space;F=P(1+\frac{i}{n})^{nt})">



