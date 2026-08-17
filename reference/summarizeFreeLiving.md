# Summarise free-living physical behaviour over one or more days

The umbrella summary: from multi-day per-epoch ENMO (plus optional
timestamps and a wear mask) it computes, per valid day and averaged
across valid days, the physical-behaviour metrics that free-living
accelerometry studies report – intensity time-use (sedentary / light /
MVPA), activity volume, the Rowlands intensity gradient and MX metrics,
activity fragmentation, the diurnal profile and WHO guideline
attainment. Only days with enough wear time are counted as valid;
non-wear epochs are excluded from the intensity tallies.

## Usage

``` r
summarizeFreeLiving(
  enmo,
  epoch_sec,
  timestamps = NULL,
  wear = NULL,
  enmo_unit = c("mg", "g"),
  thresholds = paIntensityThresholds(),
  valid_wear_hours = 10,
  steps_per_day = NULL,
  guideline_mvpa_min = 150
)
```

## Arguments

- enmo:

  Per-epoch ENMO (see
  [`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md)).

- epoch_sec:

  Epoch length in seconds.

- timestamps:

  Optional per-epoch `POSIXct` timestamps; when supplied, days are split
  on the calendar date and the diurnal profile is computed.

- wear:

  Optional per-epoch logical wear mask (`TRUE` = worn). Default: all
  worn.

- enmo_unit:

  Unit of `enmo`: `"mg"` (default) or `"g"`.

- thresholds:

  Intensity cut-points in mg (see
  [`paIntensityThresholds()`](https://x-biosignal.github.io/PhysioWearable/reference/paIntensityThresholds.md)).

- valid_wear_hours:

  Minimum wear hours for a day to be valid (default 10).

- steps_per_day:

  Optional numeric vector of steps for each day (in day order) folded
  into the per-day table and averages.

- guideline_mvpa_min:

  Weekly MVPA-equivalent minutes for guideline attainment (default 150;
  WHO 2020, counting vigorous double).

## Value

A `freeliving_summary` object: `by_day` (per-day data frame),
`aggregate` (means over valid days plus guideline attainment), `diurnal`
(or `NULL`), `n_valid_days` and settings.

## References

Rowlands (2018); Chastin (2010); WHO (2020).

## See also

[`intensityGradient()`](https://x-biosignal.github.io/PhysioWearable/reference/intensityGradient.md),
[`mxMetrics()`](https://x-biosignal.github.io/PhysioWearable/reference/mxMetrics.md),
[`activityFragmentation()`](https://x-biosignal.github.io/PhysioWearable/reference/activityFragmentation.md),
[`freeLivingICF()`](https://x-biosignal.github.io/PhysioWearable/reference/freeLivingICF.md)

## Examples

``` r
set.seed(1)
# one day, 30 s epochs: mostly sedentary with an active hour
enmo <- c(rep(5, 2 * 60 * 10), rep(120, 2 * 60), rep(5, 2 * 60 * 12))
s <- summarizeFreeLiving(enmo, epoch_sec = 30, valid_wear_hours = 0)
s$aggregate$mvpa_min
#> [1] 60
```
