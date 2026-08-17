# Real-world upper-limb use from bilateral wrist accelerometry

The field-standard free-living performance metrics for arm use – the
sensor counterpart to a clinic upper-limb capacity test. From the
affected (or dominant) and unaffected (or non-dominant) wrist activity
it computes the Use Ratio, the Magnitude Ratio, the Bilateral Magnitude,
the hours of use per arm and a laterality index. Maps to ICF d445 (hand
and arm use), the performance substrate of the d5 self-care activities.

## Usage

``` r
upperLimbUse(
  affected,
  unaffected,
  sampling_rate = NULL,
  epoch_sec = 5,
  active_threshold = 2
)
```

## Arguments

- affected, unaffected:

  The two arms' data: each an n x 3 acceleration matrix (g units) or a
  numeric vector of per-epoch ENMO (mg).

- sampling_rate:

  Sampling rate in Hz (required for raw accel input).

- epoch_sec:

  Epoch length in seconds (default 5).

- active_threshold:

  ENMO (mg) above which an epoch counts as active (default 2).

## Value

an `upper_limb_use` list: `icf_code`, `use_ratio` (affected/unaffected
active time; 1 = symmetric, \<1 = affected used less), `magnitude_ratio`
(median log activity ratio, capped +/-7; 0 = symmetric, negative =
unaffected dominant), `bilateral_magnitude` (median combined activity,
mg), `hours_affected`/`hours_unaffected`, and `laterality_index`
((aff-unaff)/(aff+unaff)).

## References

Uswatte (2005); Bailey (2014); Lang (2017).

## See also

[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md),
[`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md)

## Examples

``` r
# affected arm active half as often as the unaffected arm (per-epoch ENMO, mg)
set.seed(1)
unaff <- c(rep(10, 100), rep(0.5, 100))
aff   <- c(rep(10, 50),  rep(0.5, 150))
upperLimbUse(aff, unaff)$use_ratio        # ~ 0.5
#> [1] 0.5
```
