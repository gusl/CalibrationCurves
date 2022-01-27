# CalibrationCurves

This is a project to add statistical analyses related to probability
calibration curves and forecaster performance more broadly. This repo
focuses on binary questions.

**Status:** We already have isotonic (a.k.a. non-decreasing) binary
regression (`cgam`), and produce approximate confidence regions (see
below). Every CI method here suffers from potential non-isotonicity, but our
bootstrap CIs are an improvement over the built-in ones, in this respect.

**Future work:** Produce Bayesian intervals with Stan, using isotonic
splines to enforce shape constraint. This seems to be cleanest way.

<!-- [Testing Probability Calibrations
Andreas Bloechlinger](https://www.efmaefm.org/0EFMAMEETINGS/EFMA%20ANNUAL%20MEETINGS/2006-Madrid/papers/147279_full.pdf) -->

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
uses under the hood to enforce this shape constraint, but it does
appear to work -- the MLE seems to always be an isotonic function.  Unfortunately, isotonicity is not guaranteed for
the confidence intervals (CIs).  While our methods don't guarantee that the quantile will be
isotonic as a function of X, but they do improve this significantly.

<img
src="https://github.com/gusl/CalibrationCurves/blob/main/builtin.png" width=180 height=200>
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/boot_pseudo.png" width=180 height=200>
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/compared.png" width=180 height=200>

Our CIs can use one of several methods:
- (A) `cgam`'s built-in CIs, which do not have isotonicity and in fact
  tend to be extremely wide near the X endpoints 0 and 1, which is not ideal.
- (B) Empirical quantiles of bootstrapped fits at each X level.
  - which may or may not be smoothed, e.g. one can smoothe using 4 pseudo-observations
    that serve as a kind of Beta(1,1) prior. This is better, but note that it still does
    not guarantee isotonicity, since the endpoints tend to have
    smaller sample sizes due to `predict`'s refusal to
    extrapolate beyond the observed data.
	
We can imagine improving upon (B) by increasing the number of
pseudo-data points at the endpoints by 10x, so that it becomes overwhelmingly
unlikely for `predict`'s range to be restricted (Chance of 2^-20 per endpoint). To compensate for
this stronger prior, one would
simultaneously increase the sample size of real observations (possibly even
more). To avoid the phenomenon of data duplication leading to
undue confidence (artificially narrow CIs), we could instead use the
[Bayesian
bootstrap](https://www.sumsar.net/blog/2015/04/the-non-parametric-bootstrap-as-a-bayesian-model/).

<!-- But maybe a more interesting question is how well the bootstrap
distribution approximates posterior distributions. -->

Note re: the semantics of CIs -- the coverage levels are meant
pointwise, not for the whole curve. This means that even if you simulate perfect
calibration (see diagonal line) the
probability that *some* point falls out of the 95% confidence region
is more than 5%.
