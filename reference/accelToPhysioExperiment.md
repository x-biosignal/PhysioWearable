# Wrap tri-axial acceleration in a PhysioExperiment

Builds a `PhysioExperiment` (from PhysioCore) with a single 3-channel
`acceleration` assay (time x c(x, y, z)) at the given sampling rate.

## Usage

``` r
accelToPhysioExperiment(accel, sampling_rate, unit = "g", metadata = list())
```

## Arguments

- accel:

  An n x 3 matrix of acceleration (columns x, y, z), in g units.

- sampling_rate:

  Sampling rate in Hz.

- unit:

  Acceleration unit recorded in the channel metadata (default `"g"`).

- metadata:

  Optional named list stored in the object metadata.

## Value

A `PhysioExperiment` object.

## See also

[`readAccelCSV()`](https://x-biosignal.github.io/PhysioWearable/reference/readAccelCSV.md),
[`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md)
