# Summarise Apple Watch sleep stages into clinical metrics

Turns the `SleepAnalysis` stage intervals the Apple Watch records
(obtained from `PhysioDevices::appleHealthSeries(x, "SleepAnalysis")`)
into per-night sleep metrics. Consecutive intervals are grouped into
nights whenever the gap between them exceeds `gap_min`.

## Usage

``` r
summarizeAppleSleep(stages, gap_min = 120)
```

## Arguments

- stages:

  A data frame with `start`, `end` (`POSIXct`) and `value` (the stage
  label, e.g. `"AsleepCore"`, `"AsleepDeep"`, `"AsleepREM"`, `"Awake"`,
  `"InBed"`).

- gap_min:

  Minutes of gap that start a new night (default 120).

## Value

A data frame with one row per night: `night`, `start`, `end`, `tib_min`,
`tst_min`, `sleep_efficiency`, `waso_min`, `sol_min`, `n_awakenings`,
and `core_min`/`deep_min`/`rem_min` (when staged).

## See also

[`summarizeSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleep.md),
[`coleKripke()`](https://x-biosignal.github.io/PhysioWearable/reference/coleKripke.md)

## Examples

``` r
t0 <- as.POSIXct("2023-05-01 23:00:00", tz = "UTC")
stages <- data.frame(
  start = t0 + c(0, 3600, 3720, 7200) ,
  end   = t0 + c(3600, 3720, 7200, 10800),
  value = c("AsleepCore", "Awake", "AsleepDeep", "AsleepREM"))
summarizeAppleSleep(stages)
#>   night               start                 end tib_min tst_min
#> 1     1 2023-05-01 23:00:00 2023-05-02 02:00:00     180     178
#>   sleep_efficiency waso_min sol_min n_awakenings core_min deep_min rem_min
#> 1            0.989        2       0            1       60       58      60
```
