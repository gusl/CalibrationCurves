By gusl@.

This repo is about probabilistic forecasts of binary questions.

# Calibration Curves

Ironically, calibration reports typically do not themselves make probabilistic
claims, making it impossible for the evaluator to be evaluated! This is our attempt at fixing this.

**Project Status:**
- We have 2 methods for producing confidence regions of
calibration curves by using isotonic (a.k.a. non-decreasing) binary regression (`cgam`
library). [See
visualizations](https://github.com/gusl/CalibrationCurves#initial-comparisons). Note
that every CI method here suffers from potential non-isotonicity, but this is barely visible in our
augmented bootstrap method, which is a big improvement over the
built-in method.


**Future work:**
- Analyze performance of different CI methods
(metrics: over vs under-coverage; centrality; length).
- [Bayesian
bootstrap](https://www.sumsar.net/blog/2015/04/the-non-parametric-bootstrap-as-a-bayesian-model/)
for increasing the bootstrap sample size, for (a) mitigating non-isotonicity
issue and, (b) allowing us to try weaker "priors", which may perform better.
- Use Stan to produce Bayesian intervals, using isotonic
splines to enforce shape constraint. The result would be our first
truly isotonic method.

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
isotonic as a function of X, they do improve this significantly.


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
unlikely for `predict`'s range to be restricted (chance of ~0.368^20 per endpoint). To compensate for
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


# Initial comparisons

## Example A: over-confident forecaster
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/img/builtin.png" width=170 height=200>
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/img/boot_pseudo.png" width=170 height=200>
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/img/compared.png"
width=170 height=200>

## Example B: well-calibrated forecaster
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/img/B_builtin.png" width=170 height=200>
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/img/B_boot.png" width=170 height=200>


## Example C: under-confident forecaster
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/img/C_builtin.png" width=170 height=200>
<img
src="https://github.com/gusl/CalibrationCurves/blob/main/img/C_boot.png" width=170 height=200>


The huge CIs at the endpoints are probably an artifact of tiny sample
sizes in regions to which `cgam` cannot extrapolate. The current bootstrap method does not have this problem thanks to the data augmentation.
