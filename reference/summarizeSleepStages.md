# Summarise staged sleep into per-night clinical metrics

Vendor-agnostic engine behind
[`summarizeAppleSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeAppleSleep.md):
given sleep-stage intervals labelled by any scheme (Apple
`AsleepCore/Deep/REM`, Fitbit `light/deep/rem/wake`, ...), compute
per-night sleep metrics. Consecutive intervals are grouped into nights
whenever the gap between them exceeds `gap_min`.

## Usage

``` r
summarizeSleepStages(
  stages,
  asleep_levels,
  wake_levels = "Awake",
  inbed_levels = "InBed",
  stage_cols = NULL,
  gap_min = 120
)
```

## Arguments

- stages:

  A data frame with `start`, `end` (`POSIXct`) and a stage-label column
  named `value` or `stage`.

- asleep_levels:

  Labels counted as asleep (e.g. Apple
  `c("AsleepCore","AsleepDeep","AsleepREM")`; Fitbit
  `c("light","deep","rem")`).

- wake_levels:

  Labels counted as wake within the sleep period (default `"Awake"`;
  Fitbit `"wake"`).

- inbed_levels:

  Labels counted as explicit time in bed (default `"InBed"`).

- stage_cols:

  Optional named character vector mapping output columns to stage
  labels, e.g. `c(deep = "deep", rem = "rem")` adds `deep_min`,
  `rem_min`.

- gap_min:

  Minutes of gap that start a new night (default 120).

## Value

A data frame, one row per night: `night`, `start`, `end`, `tib_min`,
`tst_min`, `sleep_efficiency`, `waso_min`, `sol_min`, `n_awakenings`,
and one `<name>_min` column per `stage_cols` entry.

## See also

[`summarizeAppleSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeAppleSleep.md),
[`summarizeSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleep.md),
[`coleKripke()`](https://x-biosignal.github.io/PhysioWearable/reference/coleKripke.md)

## Examples

``` r
t0 <- as.POSIXct("2023-05-01 23:00:00", tz = "UTC")
stages <- data.frame(start = t0 + c(0, 3600, 7200),
                     end = t0 + c(3600, 7200, 10800),
                     stage = c("light", "deep", "rem"))
summarizeSleepStages(stages, asleep_levels = c("light", "deep", "rem"),
                     wake_levels = "wake", stage_cols = c(deep = "deep", rem = "rem"))
#>   night               start                 end tib_min tst_min
#> 1     1 2023-05-01 23:00:00 2023-05-02 02:00:00     180     180
#>   sleep_efficiency waso_min sol_min n_awakenings deep_min rem_min
#> 1                1        0       0            0       60      60
```
