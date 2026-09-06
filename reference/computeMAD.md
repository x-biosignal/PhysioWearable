# Mean Amplitude Deviation (MAD) acceleration metric

MAD is the mean absolute deviation of the tri-axial acceleration vector
magnitude about its (per-epoch) mean (Vaha-Ypya et al. 2015): for each
epoch, \\{\rm MAD} = \frac{1}{n}\sum_i \|r_i - \bar r\|\\, where \\r_i =
\sqrt{x_i^2 + y_i^2 + z_i^2}\\ is the sample vector magnitude and \\\bar
r\\ its epoch mean. It is a gravity-robust movement-intensity metric
complementary to
[`computeENMO`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md):
MAD captures the amount of *variation* in the magnitude within an epoch
(so it is insensitive to a static orientation offset), whereas ENMO
captures its *elevation* above 1 g. When an epoch length is given,
per-epoch MAD is returned; otherwise a single whole-signal MAD.

## Usage

``` r
computeMAD(accel, sampling_rate = NULL, epoch_sec = NULL, unit = c("g", "mg"))
```

## Arguments

- accel:

  An n x 3 matrix (or data frame) of acceleration in g units (columns x,
  y, z).

- sampling_rate:

  Sampling rate in Hz (required if `epoch_sec` is set).

- epoch_sec:

  Epoch length in seconds for aggregation; `NULL` returns a single MAD
  over the whole signal.

- unit:

  `"g"` (default) or `"mg"` (milli-g).

## Value

A numeric vector of MAD values (one per epoch, or a single value).

## References

Vaha-Ypya H, et al. (2015). Clin Physiol Funct Imaging 35(1):64-70.

## See also

[`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md),
[`classifyBouts()`](https://x-biosignal.github.io/PhysioWearable/reference/classifyBouts.md)

## Examples

``` r
set.seed(1)
acc <- matrix(rnorm(300, c(0, 0, 1), 0.1), ncol = 3, byrow = TRUE)
computeMAD(acc)                       # whole-signal MAD (g)
#> [1] 0.07289114
computeMAD(acc, sampling_rate = 100, epoch_sec = 1)  # per-epoch MAD
#> [1] 0.07289114
```
