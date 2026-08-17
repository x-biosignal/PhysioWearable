# Map recognised ADL activities to ICF Activities & Participation codes

Turns recognised activities into their ICF d-codes, stamped with the
`performance` qualifier (real-world doing), and attaches the time budget
when available. Activities are matched case-insensitively; unmapped
labels are dropped with a warning. The result feeds the cross-modal ICF
construct in PhysioRehab.

## Usage

``` r
adlToICF(x)
```

## Arguments

- x:

  a
  [`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md)
  result, an
  [`adlBudget()`](https://x-biosignal.github.io/PhysioWearable/reference/adlBudget.md)
  result, or a character vector of activity labels.

## Value

a data.frame `activity`, `icf_code`, `icf_title`, `qualifier`
(`"performance"`) and, when a budget is available, `minutes` and
`proportion` aggregated per ICF code.

## See also

[`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md),
[`adlBudget()`](https://x-biosignal.github.io/PhysioWearable/reference/adlBudget.md),
[`freeLivingICF()`](https://x-biosignal.github.io/PhysioWearable/reference/freeLivingICF.md)

## Examples

``` r
adlToICF(c("walking", "sitting", "walking", "eating"))
#>   icf_code                   icf_title   qualifier minutes proportion
#> 3     d450                     Walking performance      NA       0.50
#> 1     d550                      Eating performance      NA       0.25
#> 2     d415 Maintaining a body position performance      NA       0.25
```
