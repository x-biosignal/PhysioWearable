# MX physical-activity intensity metrics

The MX metrics describe the same distribution from the active end: MX is
the acceleration (mg) above which a person's most active `X` minutes are
accumulated (Rowlands et al. 2018). M60 is the intensity of the most
active hour; M120 the most active two hours. Higher MX = more intense
peak activity.

## Usage

``` r
mxMetrics(enmo_mg, epoch_sec, minutes = c(2, 5, 15, 30, 60, 120))
```

## Arguments

- enmo_mg:

  Per-epoch ENMO in milli-g.

- epoch_sec:

  Epoch length in seconds.

- minutes:

  Integer vector of X values (minutes); default
  `c(2, 5, 15, 30, 60, 120)`.

## Value

A named numeric vector `Mxx = mg`; `NA` where the recording is shorter
than X minutes.

## References

Rowlands AV, et al. (2018).

## See also

[`intensityGradient()`](https://x-biosignal.github.io/PhysioWearable/reference/intensityGradient.md),
[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)

## Examples

``` r
# most-active 60 min all at >= 200 mg
enmo <- c(rep(300, 120), rep(20, 2000))   # 30 s epochs -> 120 = 60 min
mxMetrics(enmo, epoch_sec = 30, minutes = 60)
#> M60 
#> 300 
```
