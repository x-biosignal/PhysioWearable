# Gravity-based accelerometer auto-calibration

Estimates a per-axis gain and offset that force the acceleration
magnitude to 1 g during still periods, following the GGIR sphere-fitting
method (van Hees et al. 2014). Still (non-movement) windows are
identified by a low per-axis standard deviation; their mean orientations
lie on a unit sphere in an ideally-calibrated device, and the
gain/offset are fitted by iteratively projecting onto that sphere.
Correction is `(accel - offset) * scale`.

## Usage

``` r
autoCalibrateAccel(
  accel,
  sampling_rate,
  window_sec = 10,
  still_sd = 0.013,
  min_still = 10,
  max_iter = 100L,
  tol = 1e-06
)
```

## Arguments

- accel:

  An n x 3 matrix of acceleration in g units.

- sampling_rate:

  Sampling rate in Hz.

- window_sec:

  Still-window length in seconds (default 10).

- still_sd:

  Per-axis standard-deviation threshold for a still window (default
  0.013 g).

- min_still:

  Minimum number of still windows required (default 10).

- max_iter, tol:

  Iteration cap and convergence tolerance.

## Value

An `accel_calibration` list with `scale`, `offset`, `residual` (RMS of
the still-point magnitude error after calibration), `n_still`,
`iterations`, `converged`, and a `calibrate()` function that applies the
correction to an n x 3 matrix.

## References

van Hees VT, et al. (2014). J Appl Physiol 117(7):738-744.

## See also

[`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md)
