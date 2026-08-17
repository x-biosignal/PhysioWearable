# Diurnal activity profile

Mean ENMO by hour of day (0-23), averaged over all supplied epochs – the
rest-activity rhythm of free-living behaviour. Requires per-epoch
timestamps.

## Usage

``` r
diurnalProfile(enmo_mg, timestamps)
```

## Arguments

- enmo_mg:

  Per-epoch ENMO in milli-g.

- timestamps:

  Per-epoch `POSIXct` timestamps (same length as `enmo_mg`).

## Value

A list with `hourly` (length-24 mean ENMO by hour), `peak_hour`, and
`morning`/`afternoon`/`evening`/`night` mean ENMO.

## See also

[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)
