library(testthat)
library(PhysioWearable)

test_that("step count matches a synthetic walking trace within tolerance", {
  fs <- 50
  dur <- 20
  step_hz <- 1.8
  t <- seq(0, dur, 1 / fs)
  walk <- cbind(0, 0, 1 + 0.4 * sin(2 * pi * step_hz * t))
  st <- detectSteps(walk, fs)
  expect_s3_class(st, "wearable_steps")
  expect_lte(abs(st$n_steps - step_hz * dur), 2)         # ~36 steps
  expect_equal(st$cadence_spm, st$n_steps / (length(t) / fs / 60),
               tolerance = 1e-6)
})

test_that("a still signal produces (almost) no steps", {
  fs <- 50
  still <- matrix(rep(c(0, 0, 1), each = fs * 10), ncol = 3) +
    matrix(stats::rnorm(fs * 10 * 3, 0, 0.002), ncol = 3)
  expect_lt(detectSteps(still, fs)$n_steps, 3)
})

test_that("step count scales with cadence", {
  fs <- 50; t <- seq(0, 20, 1 / fs)
  slow <- detectSteps(cbind(0, 0, 1 + 0.4 * sin(2 * pi * 1.0 * t)), fs)$n_steps
  fast <- detectSteps(cbind(0, 0, 1 + 0.4 * sin(2 * pi * 2.5 * t)), fs)$n_steps
  expect_gt(fast, slow)
})

test_that("detectSteps accepts a magnitude vector and validates input", {
  fs <- 50; t <- seq(0, 10, 1 / fs)
  vm <- 1 + 0.4 * sin(2 * pi * 1.8 * t)
  expect_gt(detectSteps(vm, fs)$n_steps, 10)
  expect_error(detectSteps(cbind(0, 0, 1), fs, min_step_hz = 5, max_step_hz = 4),
               "min_step_hz")
})

# --- regression test for adversarial-review finding (WS4-15) ------------------

test_that("detectSteps rejects a non-scalar or NA threshold", {
  x <- cbind(0, 0, 1 + 0.4 * sin(2 * pi * 1.8 * seq(0, 5, 0.02)))
  expect_error(detectSteps(x, 50, threshold = c(0.1, 0.2)), "single non-negative")
  expect_error(detectSteps(x, 50, threshold = NA), "single non-negative")
})
