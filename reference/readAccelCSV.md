# Read a raw accelerometer CSV export into a PhysioExperiment

Reads a tri-axial accelerometer CSV (GENEActiv / ActiGraph / Axivity
exports and similar) and wraps it in a `PhysioExperiment`. The x/y/z
columns are resolved by name (case-insensitive `x`/`y`/`z`, optionally
with an `accel_` prefix) or by the `columns` argument.

## Usage

``` r
readAccelCSV(path, sampling_rate, columns = NULL, skip = 0, unit = "g", ...)
```

## Arguments

- path:

  Path to the CSV file.

- sampling_rate:

  Sampling rate in Hz.

- columns:

  Optional length-3 character (column names) or integer (column indices)
  selecting the x, y, z columns; `NULL` auto-detects.

- skip:

  Number of header lines to skip before the column header (default 0).

- unit:

  Acceleration unit (default `"g"`).

- ...:

  Further arguments passed to
  [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html).

## Value

A `PhysioExperiment` object.

## See also

[`accelToPhysioExperiment()`](https://x-biosignal.github.io/PhysioWearable/reference/accelToPhysioExperiment.md)
