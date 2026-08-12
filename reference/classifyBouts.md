# Classify physical-activity intensity and detect activity bouts

Classifies each ENMO epoch into a physical-activity intensity
(sedentary, light, moderate, vigorous) and detects contiguous bouts at
or above a target intensity lasting at least a minimum duration.

## Usage

``` r
classifyBouts(
  enmo,
  epoch_sec,
  thresholds = paIntensityThresholds(),
  enmo_unit = c("mg", "g"),
  bout_level = c("moderate", "light", "vigorous"),
  min_bout_min = 1
)
```

## Arguments

- enmo:

  Per-epoch ENMO values (from
  [`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md)).

- epoch_sec:

  Epoch length in seconds.

- thresholds:

  Named intensity thresholds in mg (see
  [`paIntensityThresholds()`](https://x-biosignal.github.io/PhysioWearable/reference/paIntensityThresholds.md)).

- enmo_unit:

  Unit of `enmo`: `"mg"` (default) or `"g"`.

- bout_level:

  Minimum intensity for a bout: `"light"`, `"moderate"` (default) or
  `"vigorous"`.

- min_bout_min:

  Minimum bout duration in minutes (default 1).

## Value

A `wearable_bouts` list with `intensity` (per-epoch factor), a `bouts`
data frame (`start_epoch`, `end_epoch`, `n_epochs`, `duration_sec`,
`mean_enmo`), and `minutes` per intensity.

## References

Hildebrand M, et al. (2014).

## See also

[`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md),
[`paIntensityThresholds()`](https://x-biosignal.github.io/PhysioWearable/reference/paIntensityThresholds.md)
