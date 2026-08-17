# Time budget of recognised activities

Time budget of recognised activities

## Usage

``` r
adlBudget(recognized)
```

## Arguments

- recognized:

  a
  [`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md)
  result (or a data.frame with an `activity` column and `start_sec`).

## Value

a data.frame `activity`, `n_windows`, `minutes`, `proportion`, ordered
by time.

## See also

[`adlToICF()`](https://x-biosignal.github.io/PhysioWearable/reference/adlToICF.md)
