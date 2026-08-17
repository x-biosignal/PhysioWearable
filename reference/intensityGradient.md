# Rowlands intensity gradient

The intensity gradient summarises the *distribution* of
physical-activity intensity across the whole day: the log-log slope of
time accumulated against acceleration intensity (Rowlands et al. 2018).
A less negative gradient means relatively more time at higher
intensities. Unlike a single MVPA cut-point it uses the entire intensity
range and is cut-point free.

## Usage

``` r
intensityGradient(enmo_mg, epoch_sec, bin_width_mg = 25, max_mg = 4000)
```

## Arguments

- enmo_mg:

  Per-epoch ENMO in milli-g.

- epoch_sec:

  Epoch length in seconds.

- bin_width_mg:

  Intensity bin width in mg (default 25).

- max_mg:

  Upper edge of the binned range in mg (default 4000).

## Value

A list with `gradient` (slope), `intercept`, `r_squared`, and the `bins`
data frame (`mid_mg`, `minutes`) used in the regression.

## References

Rowlands AV, et al. (2018). Med Sci Sports Exerc 50(6):1323-1332.

## See also

[`mxMetrics()`](https://x-biosignal.github.io/PhysioWearable/reference/mxMetrics.md),
[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)

## Examples

``` r
# a power-law intensity distribution: time proportional to intensity^-2
mids <- seq(12.5, 2000, by = 25)
minutes <- 1e5 * mids^(-2)
enmo <- rep(mids, round(minutes * 2))     # 30 s epochs -> 2 epochs/min
round(intensityGradient(enmo, epoch_sec = 30)$gradient, 2)   # ~ -2
#> [1] -1.91
```
