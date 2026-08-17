# Train an ADL activity recogniser from labelled windows

Learns a k-nearest-neighbours classifier over standardised
[`adlFeatures()`](https://x-biosignal.github.io/PhysioWearable/reference/adlFeatures.md),
mapping a window's features to an activity label. Dependency-free and
model-agnostic: for a stronger engine, extract features here and
classify with PhysioML (ROCKET/torch) instead – the ICF mapping
([`adlToICF()`](https://x-biosignal.github.io/PhysioWearable/reference/adlToICF.md))
is unchanged.

## Usage

``` r
trainADL(features, labels, k = 5, window_sec = 2.56, overlap = 0.5)

# S3 method for class 'adl_model'
predict(object, newdata, ...)
```

## Arguments

- features:

  Training features: an
  [`adlFeatures()`](https://x-biosignal.github.io/PhysioWearable/reference/adlFeatures.md)
  data.frame or a numeric feature matrix (one row per window).

- labels:

  Activity label per window (length = number of windows).

- k:

  Neighbours for the vote (default 5).

- window_sec, overlap:

  Window settings to store so
  [`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md)
  can re-extract features consistently (defaults match
  [`adlFeatures()`](https://x-biosignal.github.io/PhysioWearable/reference/adlFeatures.md)).

- object:

  an `adl_model`.

- newdata:

  features to classify
  ([`adlFeatures()`](https://x-biosignal.github.io/PhysioWearable/reference/adlFeatures.md)
  data.frame or matrix).

- ...:

  unused.

## Value

an `adl_model` object.

## See also

[`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md),
[`adlFeatures()`](https://x-biosignal.github.io/PhysioWearable/reference/adlFeatures.md),
[`adlToICF()`](https://x-biosignal.github.io/PhysioWearable/reference/adlToICF.md)

## Examples

``` r
set.seed(1)
fs <- 20; t <- seq(0, 30, 1 / fs)
walk <- cbind(0.2 * sin(2 * pi * 1.8 * t), 0.2 * cos(2 * pi * 1.8 * t), 1)
sit  <- cbind(rnorm(length(t), 0, 0.01), rnorm(length(t), 0, 0.01), 1)
fw <- adlFeatures(walk, fs); fs2 <- adlFeatures(sit, fs)
feats <- rbind(fw, fs2)
labs <- c(rep("walking", nrow(fw)), rep("sitting", nrow(fs2)))
m <- trainADL(feats, labs)
m
#> <adl_model> kNN(k=5) | 44 training windows | 36 features
#>   activities: sitting, walking
```
