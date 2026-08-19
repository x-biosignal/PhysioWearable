# Changelog

## PhysioWearable 0.5.2

- [`summarizeSleepStages()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleepStages.md)
  now matches stage labels case-insensitively, so the default
  `wake_levels = "Awake"` / `inbed_levels = "InBed"` also match a
  vendor’s lowercase labels (e.g. Health Connect / Fitbit `awake`),
  which previously left WASO at 0 and inflated sleep efficiency under
  the documented default call.

## PhysioWearable 0.5.1

- [`summarizeSleepStages()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleepStages.md)
  generalises
  [`summarizeAppleSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeAppleSleep.md)
  to any vendor’s sleep-stage labels (via
  `asleep_levels`/`wake_levels`/`stage_cols`), so Fitbit
  (`wake`/`light`/`deep`/`rem`) and other wearables reuse the same
  per-night metrics.
  [`summarizeAppleSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeAppleSleep.md)
  is now a thin wrapper (unchanged behaviour).

## PhysioWearable 0.5.0

Wrist sleep and blood-oxygen analysis (Apple Watch and research
actigraphy).

- [`summarizeAppleSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeAppleSleep.md)
  turns the Apple Watch sleep STAGES (from an Apple Health export) into
  per-night clinical metrics: time in bed, total sleep time, sleep
  efficiency, WASO, onset latency, awakenings, and Core/Deep/REM
  minutes; nights are split on a configurable gap.
- [`coleKripke()`](https://x-biosignal.github.io/PhysioWearable/reference/coleKripke.md)
  scores sleep/wake from per-minute activity counts (Cole-Kripke 1992,
  with Webster rescoring), and
  [`summarizeSleep()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeSleep.md)
  reduces a sleep/wake series to the standard metrics.
- [`spo2Metrics()`](https://x-biosignal.github.io/PhysioWearable/reference/spo2Metrics.md)
  computes the oximetry indices from an SpO2 series – mean, nadir, time
  below 90% (T90/CT90) and an oxygen desaturation index (ODI) –
  auto-scaling a 0-1 fraction to percent and using timestamps when
  supplied.

## PhysioWearable 0.4.1

- [`adlToICF()`](https://x-biosignal.github.io/PhysioWearable/reference/adlToICF.md)
  now maps the remaining self-care activities (washing -\> d510,
  toileting -\> d530, grooming -\> d520), so the HAR pipeline is
  ICF-mapping-ready for all d5 self-care given task-specific training
  data.

## PhysioWearable 0.4.0

Real-world upper-limb use (self-care performance).

- [`upperLimbUse()`](https://x-biosignal.github.io/PhysioWearable/reference/upperLimbUse.md):
  field-standard free-living arm-use metrics from bilateral wrist
  accelerometry – Use Ratio, Magnitude Ratio, Bilateral Magnitude, hours
  of use per arm and a laterality index – the sensor (performance)
  counterpart to a clinic upper-limb capacity test, mapping to ICF d445
  (hand and arm use), the substrate of the d5 self-care activities.

## PhysioWearable 0.3.0

Sensor-based ADL activity recognition (HAR).

- [`adlFeatures()`](https://x-biosignal.github.io/PhysioWearable/reference/adlFeatures.md):
  windowed time/frequency features for activity recognition (per-axis
  and vector-magnitude statistics, signal-magnitude area, inter-axis
  correlations, dominant frequency, spectral energy/entropy, jerk RMS).
- [`trainADL()`](https://x-biosignal.github.io/PhysioWearable/reference/trainADL.md)
  /
  [`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md):
  a dependency-free, model-agnostic k-nearest-neighbours activity
  recogniser (swap in PhysioML ROCKET / a torch model for a stronger
  engine).
- [`adlBudget()`](https://x-biosignal.github.io/PhysioWearable/reference/adlBudget.md)
  /
  [`adlToICF()`](https://x-biosignal.github.io/PhysioWearable/reference/adlToICF.md):
  the recognised-activity time budget and its map to ICF Activities &
  Participation d-codes (walking -\> d450, stairs -\> d455, postures -\>
  d415, eating -\> d550, housework -\> d640, …) with the performance
  qualifier – answering “doing WHAT”, complementing
  [`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md)’s
  “how much / how intense”. Validated on the real UCI HAR dataset.

## PhysioWearable 0.2.0

Free-living physical-behaviour summary and ICF linking.

- [`summarizeFreeLiving()`](https://x-biosignal.github.io/PhysioWearable/reference/summarizeFreeLiving.md):
  day-level and person-level free-living metrics on top of the ENMO /
  intensity primitives – intensity time-use (sedentary/light/MVPA), the
  Rowlands intensity gradient and MX metrics, activity fragmentation
  (ASTP/SATP), the diurnal profile, WHO guideline attainment and
  valid-wear-day handling.
- [`intensityGradient()`](https://x-biosignal.github.io/PhysioWearable/reference/intensityGradient.md),
  [`mxMetrics()`](https://x-biosignal.github.io/PhysioWearable/reference/mxMetrics.md),
  [`activityFragmentation()`](https://x-biosignal.github.io/PhysioWearable/reference/activityFragmentation.md),
  [`diurnalProfile()`](https://x-biosignal.github.io/PhysioWearable/reference/diurnalProfile.md):
  the component metrics, exported standalone.
- [`freeLivingICF()`](https://x-biosignal.github.io/PhysioWearable/reference/freeLivingICF.md):
  map the metrics to ICF Activities & Participation codes stamped with
  the performance qualifier (real-world doing vs clinic capacity).

## PhysioWearable 0.1.1

### Validation

- Added GGIR gold-standard validation (VAL-10).
  [`computeENMO()`](https://x-biosignal.github.io/PhysioWearable/reference/computeENMO.md)
  is checked against GGIR’s ENMO
  ([`GGIR::g.applymetrics`](https://wadpac.github.io/GGIR/reference/g.applymetrics.html))
  on a real Axivity AX3 device recording (from GGIRread), reproducing it
  to numerical precision; the GGIR reference is bundled
  (`tests/testthat/fixtures/wearable-ggir-reference.rds`, regenerated by
  `data-raw/wearable_ggir_reference.R`) and the raw file is read from
  GGIRread at test time.
  [`autoCalibrateAccel()`](https://x-biosignal.github.io/PhysioWearable/reference/autoCalibrateAccel.md)
  (van Hees et al. 2014) is validated by ground-truth recovery of a
  known miscalibration from sphere-covering still data and cross-checked
  against an independent algebraic ellipsoid fit. GGIR/GGIRread added to
  Suggests.

## PhysioWearable 0.1.0

- Initial release: ENMO, gravity-based auto-calibration, non-wear
  detection, step detection, and raw-accelerometer I/O.
