library(testthat)
library(PhysioWearable)

test_that("ENMO of a static 1 g signal is ~0 and rises with movement", {
  still <- matrix(rep(c(0, 0, 1), each = 200), ncol = 3)
  expect_lt(max(computeENMO(still)), 1e-8)
  moving <- cbind(0.3 * sin(seq(0, 20, length.out = 1000)), 0, 1)
  expect_gt(mean(computeENMO(moving)), 0)
})

test_that("computeENMO truncates negative values and aggregates by epoch", {
  # sub-1g magnitude -> raw ENMO negative -> truncated to 0
  low <- matrix(rep(c(0, 0, 0.5), each = 100), ncol = 3)
  expect_equal(max(computeENMO(low)), 0)
  # 2 s epochs at 50 Hz -> 100 samples/epoch
  x <- cbind(0, 0, rep(c(1.2, 1.0), each = 100))
  ep <- computeENMO(x, sampling_rate = 50, epoch_sec = 2)
  expect_length(ep, 2)
  expect_gt(ep[1], 0.1)          # first epoch moving (1.2 g)
  expect_equal(ep[2], 0)         # second epoch static (1.0 g)
})

test_that("computeENMO validates its input", {
  expect_error(computeENMO(1:10), "n x 3")
  expect_error(computeENMO(matrix(c(1, NA, 1, 1, 1, 1), ncol = 3)),
               "non-finite")
  expect_error(computeENMO(matrix(0, 10, 3), epoch_sec = 5), "sampling_rate")
})

test_that("mg unit scales ENMO by 1000", {
  x <- cbind(0, 0, rep(1.1, 100))
  expect_equal(computeENMO(x, unit = "mg"), computeENMO(x) * 1000)
})

# --- intensity classification and bouts --------------------------------------

test_that("classifyBouts classifies intensities and detects bouts", {
  # 5 s epochs: 15 min sedentary, 10 min moderate, 5 min sedentary
  enmo <- c(rep(30, 180), rep(150, 120), rep(20, 60))
  b <- classifyBouts(enmo, epoch_sec = 5, min_bout_min = 1)
  expect_s3_class(b, "wearable_bouts")
  expect_equal(unname(b$minutes["moderate"]), 10)
  expect_equal(unname(b$minutes["sedentary"]), 20)
  expect_equal(nrow(b$bouts), 1)
  expect_equal(b$bouts$duration_sec, 600)
})

test_that("classifyBouts drops bouts below the minimum duration", {
  # a 30 s moderate burst with a 1 min minimum bout -> no bout
  enmo <- c(rep(20, 100), rep(200, 6), rep(20, 100))
  b <- classifyBouts(enmo, epoch_sec = 5, min_bout_min = 1)
  expect_equal(nrow(b$bouts), 0)
})

test_that("paIntensityThresholds are ordered cut-points", {
  th <- paIntensityThresholds()
  expect_named(th, c("light", "moderate", "vigorous"))
  expect_true(all(diff(th) > 0))
})

# --- regression tests for adversarial-review findings (WS4-15) ----------------

test_that("classifyBouts coerces an unnamed length-3 threshold and validates", {
  b <- classifyBouts(rep(150, 120), epoch_sec = 5, thresholds = c(45, 100, 430))
  expect_equal(unname(b$minutes["moderate"]), 10)
  expect_error(classifyBouts(rep(150, 10), 5, thresholds = c(45, 100)),
               "named light")
  expect_error(classifyBouts(rep(150, 10), 5, min_bout_min = -1),
               "non-negative")
})
