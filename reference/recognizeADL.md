# Recognise ADL activities in a raw recording

Windows a raw tri-axial signal, extracts
[`adlFeatures()`](https://x-biosignal.github.io/PhysioWearable/reference/adlFeatures.md)
and classifies each window with a trained
[`trainADL()`](https://x-biosignal.github.io/PhysioWearable/reference/trainADL.md)
model, giving the activity per window.

## Usage

``` r
recognizeADL(
  model,
  accel,
  sampling_rate,
  window_sec = model$window_sec,
  overlap = model$overlap
)
```

## Arguments

- model:

  an `adl_model`.

- accel:

  an n x 3 acceleration matrix (g units).

- sampling_rate:

  sampling rate in Hz.

- window_sec, overlap:

  window settings (default: the model's).

## Value

a data.frame with `window`, `start_sec`, `end_sec` and `activity`.

## See also

[`adlBudget()`](https://x-biosignal.github.io/PhysioWearable/reference/adlBudget.md),
[`adlToICF()`](https://x-biosignal.github.io/PhysioWearable/reference/adlToICF.md)
