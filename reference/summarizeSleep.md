# Summarise a sleep/wake series into standard sleep metrics

Summarise a sleep/wake series into standard sleep metrics

## Usage

``` r
summarizeSleep(sleep_wake, epoch = 60, spt = NULL)
```

## Arguments

- sleep_wake:

  Integer/logical per-epoch sleep(1)/wake(0) vector (e.g. from
  [`coleKripke()`](https://x-biosignal.github.io/PhysioWearable/reference/coleKripke.md)).

- epoch:

  Epoch length in seconds (default 60).

- spt:

  Optional integer length-2 vector `c(start, end)` of epoch indices
  bounding the sleep-period (time in bed). If `NULL` (default) it spans
  the first to the last sleep epoch.

## Value

A one-row data frame: `tib_min` (time in bed), `tst_min` (total sleep
time), `sleep_efficiency` (TST/TIB), `waso_min` (wake after sleep
onset), `sol_min` (sleep-onset latency), `n_awakenings`.

## See also

[`coleKripke()`](https://x-biosignal.github.io/PhysioWearable/reference/coleKripke.md)

## Examples

``` r
sw <- c(rep(0, 5), rep(1, 40), 0, 0, rep(1, 30))
summarizeSleep(sw)
#>   tib_min tst_min sleep_efficiency waso_min sol_min n_awakenings
#> 1      72      70        0.9722222        2       0            1
```
