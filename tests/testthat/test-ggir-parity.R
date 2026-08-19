library(testthat)
library(PhysioWearable)

# VAL-10: validate PhysioWearable against GGIR (the accelerometer gold standard).
#
# Two parts:
#  (1) ENMO parity on REAL Axivity AX3 device data. GGIR's ENMO (g.applymetrics)
#      on the real recording is bundled as a fixture (tests/testthat/fixtures/
#      wearable-ggir-reference.rds); the test re-reads the raw file from GGIRread
#      and checks PhysioWearable's computeENMO reproduces GGIR's values. Gated on
#      GGIRread (needed to parse the .cwa); the reference itself is bundled.
#  (2) Auto-calibration (van Hees et al. 2014) validated by GROUND-TRUTH RECOVERY
#      of a known miscalibration, cross-checked with an independent algebraic
#      ellipsoid fit. Self-contained (no external data), so it always runs.
# Provenance / regeneration: data-raw/wearable_ggir_reference.R (GGIR 3.3.8).

test_that("computeENMO reproduces GGIR's ENMO on real Axivity AX3 data", {
  skip_if_not_installed("GGIRread")
  ref <- readRDS(test_path("fixtures", "wearable-ggir-reference.rds"))
  f <- system.file("testfiles/ax3_testfile.cwa", package = "GGIRread")
  skip_if(f == "", "GGIRread AX3 test file not available")

  d <- GGIRread::readAxivity(f, start = 0, end = Inf, progressBar = FALSE)
  xyz <- as.matrix(d$data[, c("x", "y", "z")])
  enmo_pw <- computeENMO(xyz, sampling_rate = ref$sampling_rate,
                         epoch_sec = ref$epoch_sec, unit = "mg")

  n <- min(length(enmo_pw), length(ref$enmo_ggir_mg))
  a <- enmo_pw[seq_len(n)]; b <- ref$enmo_ggir_mg[seq_len(n)]
  # Identical metric definition -> agreement to numerical precision.
  expect_equal(a, b, tolerance = 1e-6)
  expect_lt(max(abs(a - b)), 1e-3)          # < 0.001 mg
})

# ---- Auto-calibration ground-truth recovery (always-running) ----

# Build a device-at-rest recording spanning the sphere with a KNOWN miscalibration.
.make_sphere <- function(S_true, O_true, sr = 100L, hold_s = 10L, M = 40L,
                         noise = 0.005, seed = 20260806L) {
  set.seed(seed)
  n_hold <- hold_s * sr
  i <- seq_len(M) - 0.5
  phi <- acos(1 - 2 * i / M); theta <- pi * (1 + sqrt(5)) * i
  U <- cbind(sin(phi) * cos(theta), sin(phi) * sin(theta), cos(phi))
  do.call(rbind, lapply(seq_len(M), function(k) {
    u <- U[k, ]
    base <- sweep(matrix(u, n_hold, 3, byrow = TRUE), 2, S_true, "/")
    base <- sweep(base, 2, O_true, "+")
    base + matrix(rnorm(n_hold * 3, 0, noise), n_hold, 3)   # sd < still_sd (0.013)
  }))
}

test_that("van Hees auto-calibration recovers a known miscalibration", {
  S_true <- c(1.030, 0.970, 1.050); O_true <- c(0.040, -0.020, 0.030)
  rows <- .make_sphere(S_true, O_true)
  cal <- autoCalibrateAccel(rows, sampling_rate = 100)

  expect_true(cal$converged)
  expect_gte(cal$n_still, 10)
  expect_lt(max(abs(cal$scale - S_true)), 5e-3)     # gains recovered
  expect_lt(max(abs(cal$offset - O_true)), 5e-3)    # offsets recovered
  expect_lt(cal$residual, 1e-3)                     # unit-sphere residual
})

test_that("auto-calibration agrees with an independent algebraic ellipsoid fit", {
  S_true <- c(1.030, 0.970, 1.050); O_true <- c(0.040, -0.020, 0.030)
  rows <- .make_sphere(S_true, O_true)
  cal <- autoCalibrateAccel(rows, sampling_rate = 100)

  # Independent solver: still-window means -> algebraic axis-aligned ellipsoid fit
  # (SVD null space of [d^2, d, 1]), a different formulation from the iterative lm.
  win <- 10L * 100L; nwin <- nrow(rows) %/% win
  D <- t(vapply(seq_len(nwin), function(w)
    colMeans(rows[((w - 1) * win + 1):(w * win), , drop = FALSE]), numeric(3)))
  A <- cbind(D^2, D, 1)
  p <- svd(A)$v[, ncol(A)]
  a <- p[1:3]; b <- p[4:6]
  s_alg <- sqrt(abs(a)); o_alg <- -b / (2 * a)
  cal_alg <- sweep(sweep(D, 2, o_alg), 2, s_alg, "*")
  s_alg <- s_alg / median(sqrt(rowSums(cal_alg^2)))

  expect_lt(max(abs(cal$scale - s_alg)), 1e-2)
  expect_lt(max(abs(cal$offset - o_alg)), 1e-2)
})
