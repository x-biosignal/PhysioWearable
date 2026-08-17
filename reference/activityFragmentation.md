# Physical-activity fragmentation

Fragmentation metrics describe how activity and rest are *accumulated* –
many short bouts (fragmented) versus few long ones. Reported for both
the active and sedentary states: mean bout duration, bout counts, the
transition probabilities (active-to-sedentary `astp`,
sedentary-to-active `satp`; each the reciprocal of the mean bout length
in the origin state, Chastin et al. 2010) and the Gini index of
sedentary-bout durations.

## Usage

``` r
activityFragmentation(intensity, epoch_sec)
```

## Arguments

- intensity:

  A per-epoch intensity factor (from
  [`classifyBouts()`](https://x-biosignal.github.io/PhysioWearable/reference/classifyBouts.md))
  or a logical/0-1 vector marking active epochs (TRUE = active). When a
  factor is given, any level other than `"sedentary"` counts as active.

- epoch_sec:

  Epoch length in seconds.

## Value

A list of fragmentation metrics (durations in minutes).

## References

Chastin SFM, Granat MH (2010). Gait Posture 31(1):82-86.

## See also

[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)

## Examples

``` r
# alternating 4-epoch active / 6-epoch sedentary blocks
act <- rep(rep(c(TRUE, FALSE), c(4, 6)), 5)
activityFragmentation(act, epoch_sec = 60)$astp   # 1/4 = 0.25
#> [1] 0.25
```
