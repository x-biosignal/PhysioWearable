# Cole-Kripke actigraphy sleep/wake scoring

Scores each epoch as sleep or wake from per-epoch activity counts using
the Cole-Kripke algorithm: a weighted sum of the surrounding epochs'
activity is thresholded (`D < 1` =\> sleep). Weights are the classic
1-minute set.

## Usage

``` r
coleKripke(counts, rescore = TRUE)
```

## Arguments

- counts:

  Numeric vector of per-epoch activity counts (one per minute).

- rescore:

  If `TRUE` (default) apply the Webster rescoring rules that flip short
  isolated sleep bouts after sustained wake to wake.

## Value

An integer vector the same length as `counts`: `1` = sleep, `0` = wake.

## References

Cole RJ, Kripke DF, Gruen W, Mullaney DJ, Gillin JC (1992). "Automatic
sleep/wake identification from wrist activity." Sleep 15:461-469.

## See also

[`summarizeSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleep.md),
[`summarizeAppleSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeAppleSleep.md)

## Examples

``` r
set.seed(1)
counts <- c(rpois(30, 40), rpois(60, 2), rpois(20, 45))  # active, quiet, active
table(coleKripke(counts))
#> 
#>   0   1 
#> 105   5 
```
