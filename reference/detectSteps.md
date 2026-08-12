# Detect steps from tri-axial acceleration

Counts steps by peak-detecting the dynamic acceleration magnitude
(vector magnitude minus gravity). Peaks must exceed a prominence
threshold and be separated by at least the shortest plausible step
interval (`1 / max_step_hz`), which suppresses double counts.

## Usage

``` r
detectSteps(
  accel,
  sampling_rate,
  min_step_hz = 0.5,
  max_step_hz = 4,
  threshold = NULL,
  min_amplitude = 0.05
)
```

## Arguments

- accel:

  An n x 3 matrix of acceleration in g units, or a numeric vector
  already representing an acceleration magnitude.

- sampling_rate:

  Sampling rate in Hz.

- min_step_hz, max_step_hz:

  Plausible step-frequency range in Hz (defaults 0.5 and 4).

- threshold:

  Minimum peak height in the dynamic magnitude (g). `NULL` uses
  `max(0.5 * sd(dynamic magnitude), min_amplitude)`; the absolute floor
  stops sensor noise in a still recording from being counted as steps.

- min_amplitude:

  Absolute floor (g) for the automatic threshold (default 0.05).

## Value

A `wearable_steps` list with `n_steps`, `step_index` (sample indices of
detected steps), and `cadence_spm` (steps per minute).

## References

Any peak-based pedometer (e.g. Zijlstra & Hof 2003).

## See also

[`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md)

## Examples

``` r
fs <- 50; t <- seq(0, 10, 1 / fs)
walk <- cbind(0, 0, 1 + 0.4 * sin(2 * pi * 1.8 * t))  # 1.8 steps/s
detectSteps(walk, fs)$n_steps
#> [1] 18
```
