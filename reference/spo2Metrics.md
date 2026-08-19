# Oximetry (SpO2) metrics

Computes the standard blood-oxygen summary indices from an SpO2 series.
Accepts SpO2 as a percentage (90) or a fraction (0.90; auto-detected and
scaled). When `time` is supplied the time-below-threshold and
desaturation index are duration-weighted; otherwise they are sample
proportions/counts.

## Usage

``` r
spo2Metrics(spo2, time = NULL, threshold = 90, desat = 3, window = 12)
```

## Arguments

- spo2:

  Numeric SpO2 series (percent or 0-1 fraction).

- time:

  Optional sample times as `POSIXct` or numeric seconds (same length and
  order as `spo2`). Enables `t90_min` and per-hour `odi`.

- threshold:

  Desaturation threshold percent for T90/CT90 (default 90).

- desat:

  Drop (percentage points) below the rolling baseline that defines a
  desaturation event (default 3; 4 is also common).

- window:

  Rolling-baseline length in samples for event detection (default 12).

## Value

An `spo2_metrics` object: `mean`, `nadir`, `pct_below`, `ct90`,
`t90_min`, `n_desat`, `odi` (events/hour), plus the settings.

## References

Chung F et al. (2012) oximetry desaturation indices; standard ODI/CT90
definitions used in sleep-disordered-breathing screening.

## See also

[`summarizeAppleSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeAppleSleep.md)

## Examples

``` r
set.seed(1)
spo2 <- pmin(100, pmax(80, 97 + round(rnorm(200))))
spo2[50:55] <- 88   # a desaturation
spo2Metrics(spo2)
#> <spo2_metrics> n=200  mean=96.8%  nadir=88.0%
#>   <90%: 3.0% of samples
#>   desaturations (>=3 pt): 31
#>   note: no timing supplied (or Apple Watch spot checks) -> ODI/T90 unavailable or approximate
```
