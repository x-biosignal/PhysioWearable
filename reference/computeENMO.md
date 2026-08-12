# Euclidean Norm Minus One (ENMO) acceleration metric

ENMO is the vector magnitude of tri-axial acceleration minus one
gravity, with negative values truncated to zero (van Hees et al. 2013).
For a perfectly still sensor (magnitude 1 g) ENMO is 0; movement raises
it. When an epoch length is given, per-epoch mean ENMO is returned.

## Usage

``` r
computeENMO(accel, sampling_rate = NULL, epoch_sec = NULL, unit = c("g", "mg"))
```

## Arguments

- accel:

  An n x 3 matrix (or data frame) of acceleration in g units (columns x,
  y, z).

- sampling_rate:

  Sampling rate in Hz (required if `epoch_sec` is set).

- epoch_sec:

  Epoch length in seconds for aggregation; `NULL` returns the per-sample
  ENMO.

- unit:

  `"g"` (default) or `"mg"` (milli-g).

## Value

A numeric vector of ENMO values (per sample, or per epoch).

## References

van Hees VT, et al. (2013). PLoS ONE 8(4):e61691.

## See also

[`classifyBouts()`](https://x-biosignal.github.io/PhysioWearable/reference/classifyBouts.md),
[`autoCalibrateAccel()`](https://x-biosignal.github.io/PhysioWearable/reference/autoCalibrateAccel.md)

## Examples

``` r
still <- matrix(rep(c(0, 0, 1), each = 100), ncol = 3)
max(computeENMO(still))          # ~ 0 for a static 1 g signal
#> [1] 0
```
