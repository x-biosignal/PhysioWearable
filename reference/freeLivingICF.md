# Map free-living metrics to ICF codes (performance qualifier)

Returns the ICF Activities & Participation codes for free-living
physical-behaviour metrics, each labelled with the ICF `performance`
qualifier – the distinguishing feature of free-living monitoring, which
captures what a person actually does in daily life rather than the
`capacity` a clinic test measures. When a
[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)
result is supplied, each mapped metric's aggregate value is attached.

## Usage

``` r
freeLivingICF(x = NULL, hub = NULL)
```

## Arguments

- x:

  A `freeliving_summary` (from
  [`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md))
  or a character vector of metric ids; `NULL` (default) returns the full
  free-living map.

- hub:

  Optional `PhysioAnnotationHub` object passed through to the ontology
  lookup.

## Value

A data frame with `metric`, `icf_code`, `icf_title`, `qualifier` (always
`"performance"`) and, for a summary input, `value`.

## Details

Uses the maintained ontology in the suggested package
PhysioAnnotationHub when available (its free-living rows), falling back
to a built-in table otherwise.

## See also

[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)

## Examples

``` r
freeLivingICF()                       # the free-living metric -> ICF map
#>                     metric icf_code                  icf_title   qualifier
#> 1            steps_per_day     d450                    Walking performance
#> 2                 mvpa_min     d570 Looking after one's health performance
#> 3            sedentary_min     d570 Looking after one's health performance
#> 4 physical_activity_volume     d570 Looking after one's health performance
#> 5            walking_bouts     d455              Moving around performance
freeLivingICF(c("mvpa_min", "steps_per_day"))
#>          metric icf_code                  icf_title   qualifier
#> 1 steps_per_day     d450                    Walking performance
#> 2      mvpa_min     d570 Looking after one's health performance
```
