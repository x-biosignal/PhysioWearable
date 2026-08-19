# Summarise Apple Watch sleep stages into clinical metrics

Apple-specific wrapper around
[`summarizeSleepStages()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleepStages.md)
for the `SleepAnalysis` stage intervals the Apple Watch records (from
`PhysioDevices::appleHealthSeries(x, "SleepAnalysis")`): asleep is
`AsleepCore/Deep/REM`, and `core_min`/`deep_min`/`rem_min` are reported.

## Usage

``` r
summarizeAppleSleep(stages, gap_min = 120)
```

## Arguments

- stages:

  A data frame with `start`, `end` (`POSIXct`) and `value`
  (`"AsleepCore"`, `"AsleepDeep"`, `"AsleepREM"`, `"Awake"`, `"InBed"`).

- gap_min:

  Minutes of gap that start a new night (default 120).

## Value

See
[`summarizeSleepStages()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleepStages.md);
with `core_min`/`deep_min`/`rem_min`.

## See also

[`summarizeSleepStages()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleepStages.md),
[`summarizeSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleep.md)

## Examples

``` r
t0 <- as.POSIXct("2023-05-01 23:00:00", tz = "UTC")
stages <- data.frame(
  start = t0 + c(0, 3600, 3720, 7200),
  end   = t0 + c(3600, 3720, 7200, 10800),
  value = c("AsleepCore", "Awake", "AsleepDeep", "AsleepREM"))
summarizeAppleSleep(stages)
#>   night               start                 end tib_min tst_min
#> 1     1 2023-05-01 23:00:00 2023-05-02 02:00:00     180     178
#>   sleep_efficiency waso_min sol_min n_awakenings core_min deep_min rem_min
#> 1            0.989        2       0            1       60       58      60
```
