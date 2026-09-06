# PhysioWearable

[![r-universe](https://x-biosignal.r-universe.dev/badges/PhysioWearable)](https://x-biosignal.r-universe.dev/PhysioWearable)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`PhysioWearable` analyzes free-living tri-axial accelerometry. It covers CSV
ingestion, gravity-based calibration, ENMO, non-wear detection, step detection,
physical-activity intensity classification, bout summaries, and optional
conversion to the common `PhysioExperiment` model.

## Installation

```r
options(repos = c(
  xbiosignal = "https://x-biosignal.r-universe.dev",
  CRAN = "https://cloud.r-project.org"
))
install.packages("PhysioWearable")
```

## Quick start

```r
library(PhysioWearable)

sampling_rate <- 50
time <- seq(0, 20, by = 1 / sampling_rate)
acceleration <- cbind(
  x = 0,
  y = 0,
  z = 1 + 0.4 * sin(2 * pi * 1.8 * time)
)

enmo <- computeENMO(
  acceleration,
  sampling_rate = sampling_rate,
  epoch_sec = 5,
  unit = "mg"
)
steps <- detectSteps(acceleration, sampling_rate)

enmo
steps$n_steps
```

## Main functions

| Stage | Functions |
|---|---|
| Import and model conversion | `readAccelCSV()`, `accelToPhysioExperiment()` |
| Calibration | `autoCalibrateAccel()` |
| Movement metric | `computeENMO()` |
| Wear-time handling | `detectNonWear()` |
| Ambulation | `detectSteps()` |
| Intensity and bouts | `paIntensityThresholds()`, `classifyBouts()` |

Device placement, units, calibration, sampling rate, non-wear parameters, and
population-specific intensity thresholds should be recorded with study
methods. Default outputs are research summaries, not clinical classifications.

## Ecosystem role

`PhysioWearable` converts raw free-living acceleration into quality-control and
activity summaries. Device-specific multi-signal imports belong in
`PhysioDevices`; downstream statistical and clinical analyses can consume the
shared model or returned tables.

## Documentation

- [Function reference](https://x-biosignal.r-universe.dev/PhysioWearable)
- [Source repository](https://github.com/x-biosignal/PhysioWearable)
- [Issue tracker](https://github.com/x-biosignal/PhysioWearable/issues)

## Citation

```r
citation("PhysioWearable")
```

See the ecosystem [governance](https://github.com/x-biosignal/PhysioExperiment/blob/main/GOVERNANCE.md),
[support policy](https://github.com/x-biosignal/PhysioExperiment/blob/main/SUPPORT.md),
and [contribution guide](https://github.com/x-biosignal/PhysioExperiment/blob/main/CONTRIBUTING.md).

## Author and license

Author and maintainer: **Yusuke Matsui**. Licensed under the [MIT License](LICENSE).
