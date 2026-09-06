# ENMO-abs (ENMOa) acceleration metric

ENMOa is the "always-positive" companion of
[`computeENMO`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md):
the vector magnitude minus one gravity, with the *absolute value* taken
instead of truncating negatives to zero, \\{\rm ENMOa} = \|r - 1\|\\
with \\r = \sqrt{x^2+y^2+z^2}\\ (van Hees et al. 2013). It differs from
ENMO only where the magnitude dips below 1 g (deceleration / partial
free-fall), which ENMO truncates away; ENMOa retains that movement, so
it is used when the sensor calibration is imperfect (a persistent sub-1
g offset would otherwise be lost by ENMO's truncation). When an epoch
length is given, per-epoch mean ENMOa is returned.

## Usage

``` r
computeENMOa(
  accel,
  sampling_rate = NULL,
  epoch_sec = NULL,
  unit = c("g", "mg")
)
```

## Arguments

- accel:

  An n x 3 matrix (or data frame) of acceleration in g units (columns x,
  y, z).

- sampling_rate:

  Sampling rate in Hz (required if `epoch_sec` is set).

- epoch_sec:

  Epoch length in seconds for aggregation; `NULL` returns the per-sample
  ENMOa.

- unit:

  `"g"` (default) or `"mg"` (milli-g).

## Value

A numeric vector of ENMOa values (per sample, or per epoch).

## References

van Hees VT, et al. (2013). PLoS ONE 8(4):e61691.

## See also

[`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md),
[`computeMAD()`](https://x-biosignal.github.io/PhysioWearable/reference/computeMAD.md)

## Examples

``` r
set.seed(1)
acc <- matrix(rnorm(300, c(0, 0, 1), 0.1), ncol = 3, byrow = TRUE)
mean(computeENMOa(acc))          # >= mean(computeENMO): retains sub-1 g dips
#> [1] 0.07291543
```
