# Free-living accelerometry with PhysioWearable

PhysioWearable analyses raw tri-axial accelerometry following the GGIR
methodology. Its analysis layer is **device-agnostic**: once a recording
is a matrix of acceleration in *g* units, the same functions apply
whether the data came from a GENEActiv, ActiGraph or Axivity device, or
from a consumer wearable export. This vignette uses only synthetic data,
so it runs offline and is fully reproducible — no device file or API is
required.

``` r

library(PhysioWearable)
#> PhysioWearable v0.5.5 - free-living wearable accelerometry
set.seed(1)
```

## From raw acceleration to ENMO

The core metric is ENMO — the Euclidean norm of the acceleration vector
minus one gravity, with negatives truncated to zero. A perfectly still
sensor (1 *g*) gives ENMO 0; movement raises it. Here is a two-minute
synthetic snippet at 30 Hz: one minute still, then one minute of 1.8 Hz
“walking”.

``` r

fs  <- 30
t1  <- seq_len(60 * fs) / fs
n1  <- length(t1)
still <- cbind(x = rnorm(n1, 0, 0.01), y = rnorm(n1, 0, 0.01),
               z = 1 + rnorm(n1, 0, 0.01))         # ~1 g on z, sensor still
walk  <- cbind(x = 0.3 * sin(2 * pi * 1.8 * t1), y = 0,
               z = 1 + 0.3 * cos(2 * pi * 1.8 * t1))  # 1.8 Hz movement
accel <- rbind(still, walk)

enmo_epoch <- computeENMO(accel, sampling_rate = fs, epoch_sec = 5, unit = "mg")
round(enmo_epoch)            # ~0 mg while still, higher during "walking"
#>  [1]   4   4   4   3   4   4   4   4   4   3   4   4 106 106 106 106 106 106 106
#> [20] 106 106 106 106 106
```

## Step detection and intensity

[`detectSteps()`](https://x-biosignal.github.io/PhysioWearable/reference/detectSteps.md)
peak-counts the dynamic acceleration;
[`classifyBouts()`](https://x-biosignal.github.io/PhysioWearable/reference/classifyBouts.md)
turns per-epoch ENMO into intensity categories using published mg
cut-points.

``` r

detectSteps(accel, sampling_rate = fs)$n_steps
#> [1] 108

paIntensityThresholds()                 # light / moderate / vigorous, mg
#>    light moderate vigorous 
#>       45      100      430
bouts <- classifyBouts(enmo_epoch, epoch_sec = 5, enmo_unit = "mg",
                       min_bout_min = 0)
bouts$minutes
#> sedentary     light  moderate  vigorous 
#>         1         0         1         0
```

## A day-level free-living summary

Day- and person-level metrics are built on per-epoch ENMO. Below is a
synthetic 14-hour day in 30-second epochs (mostly sedentary with a
one-hour brisk block);
[`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)
returns the metrics free-living studies report — intensity time-use, the
Rowlands intensity gradient, MX metrics, activity fragmentation and WHO
guideline attainment.

``` r

ep  <- 30
day <- c(rep(5,   120 * 10),   # 10 h mostly sedentary (5 mg)
         rep(60,  120 * 2),    # 2 h light (60 mg)
         rep(160, 120 * 1),    # 1 h brisk / moderate (160 mg)
         rep(5,   120 * 1))    # 1 h sedentary
summary <- summarizeFreeLiving(day, epoch_sec = ep, enmo_unit = "mg")
summary$aggregate[c("sedentary_min", "light_min", "mvpa_min",
                    "intensity_gradient")]
#> $sedentary_min
#> [1] 660
#> 
#> $light_min
#> [1] 120
#> 
#> $mvpa_min
#> [1] 60
#> 
#> $intensity_gradient
#> [1] -0.9478508
summary$aggregate$meets_guideline
#> [1] TRUE
```

[`intensityGradient()`](https://x-biosignal.github.io/PhysioWearable/reference/intensityGradient.md)
and
[`mxMetrics()`](https://x-biosignal.github.io/PhysioWearable/reference/mxMetrics.md)
are also available on their own:

``` r

round(intensityGradient(day, epoch_sec = ep)$gradient, 2)
#> [1] -0.95
mxMetrics(day, epoch_sec = ep, minutes = c(30, 60))
#> M30 M60 
#> 160 160
```

## Where next

The free-living metrics link to the ICF Activities and Participation
performance qualifier via
[`freeLivingICF()`](https://x-biosignal.github.io/PhysioWearable/reference/freeLivingICF.md)
and
[`adlToICF()`](https://x-biosignal.github.io/PhysioWearable/reference/adlToICF.md).
Raw device exports are read with
[`readAccelCSV()`](https://x-biosignal.github.io/PhysioWearable/reference/readAccelCSV.md)
into a PhysioExperiment object; the recording can be gravity-calibrated
with
[`autoCalibrateAccel()`](https://x-biosignal.github.io/PhysioWearable/reference/autoCalibrateAccel.md)
and screened for non-wear with
[`detectNonWear()`](https://x-biosignal.github.io/PhysioWearable/reference/detectNonWear.md)
before the analysis above.
