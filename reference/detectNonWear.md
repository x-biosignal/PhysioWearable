# Detect non-wear periods

Flags non-wear windows where the accelerometer is stationary: at least
`min_axes` of the three axes have a low standard deviation and value
range over a long window (van Hees et al. 2011).

## Usage

``` r
detectNonWear(
  accel,
  sampling_rate,
  window_min = 60,
  step_min = NULL,
  sd_thresh = 0.013,
  range_thresh = 0.05,
  min_axes = 2L
)
```

## Arguments

- accel:

  An n x 3 matrix of acceleration in g units.

- sampling_rate:

  Sampling rate in Hz.

- window_min:

  Window length in minutes (default 60).

- step_min:

  Window step in minutes; `NULL` uses `window_min / 4`. A sliding
  (overlapping) window prevents a non-wear period from being diluted
  across a block boundary.

- sd_thresh:

  Per-axis standard-deviation threshold (default 0.013 g).

- range_thresh:

  Per-axis value-range threshold (default 0.050 g).

- min_axes:

  Number of axes that must meet both criteria (default 2).

## Value

A `nonwear` list with a per-window `windows` data frame (`window`,
`start_time`, `end_time`, `nonwear`) and the `nonwear_fraction`
(fraction of samples covered by any non-wear window).

## References

van Hees VT, et al. (2011). PLoS ONE 6(7):e22922.
