library(testthat)
library(PhysioWearable)

test_that("auto-calibration recovers the gain/offset of mis-scaled data", {
  d <- .miscalibrated_still()
  cal <- autoCalibrateAccel(d$raw, sampling_rate = 30, window_sec = 10,
                            min_still = 10)
  expect_s3_class(cal, "accel_calibration")
  expect_true(cal$converged)
  expect_lt(cal$residual, 0.005)                         # magnitude ~ 1 g
  expect_equal(cal$scale, d$scale_true, tolerance = 0.02)
  expect_equal(cal$offset, d$offset_true, tolerance = 0.02)
})

test_that("the calibration correction restores unit magnitude", {
  d <- .miscalibrated_still()
  cal <- autoCalibrateAccel(d$raw, 30)
  corrected <- cal$calibrate(d$M)                        # the still orientations
  mag <- sqrt(rowSums(corrected^2))
  expect_lt(sqrt(mean((mag - 1)^2)), 0.01)
  # an already-calibrated recording is left essentially unchanged
  clean <- .miscalibrated_still(scale_true = c(1, 1, 1),
                                offset_true = c(0, 0, 0))
  cal0 <- autoCalibrateAccel(clean$raw, 30)
  expect_equal(cal0$scale, c(1, 1, 1), tolerance = 0.02)
  expect_equal(cal0$offset, c(0, 0, 0), tolerance = 0.02)
})

test_that("autoCalibrateAccel errors when there are too few still periods", {
  # continuously moving signal -> no still windows
  fs <- 30; t <- seq(0, 60, 1 / fs)
  moving <- cbind(0.5 * sin(2 * pi * t), 0.5 * cos(2 * pi * t),
                  1 + 0.5 * sin(2 * pi * t))
  expect_error(autoCalibrateAccel(moving, fs), "still windows")
})

# --- non-wear detection ------------------------------------------------------

test_that("detectNonWear flags a still segment and not a moving one", {
  fs <- 10
  n <- fs * 60 * 30                                       # 30-min windows
  set.seed(2)
  still <- matrix(rep(c(0, 0, 1), each = n), ncol = 3) +
    matrix(stats::rnorm(n * 3, 0, 0.002), ncol = 3)
  tt <- seq_len(n) / fs
  moving <- cbind(0.3 * sin(2 * pi * 1.5 * tt), 0.2 * cos(2 * pi * 1.5 * tt),
                  1 + 0.3 * sin(2 * pi * 1.5 * tt))
  nw <- detectNonWear(rbind(still, moving), fs, window_min = 30)
  expect_s3_class(nw, "nonwear")
  expect_true(nw$windows$nonwear[1])
  expect_false(nw$windows$nonwear[2])
  expect_equal(nw$nonwear_fraction, 0.5)
})

# --- regression tests for adversarial-review findings (WS4-15) ----------------

test_that("auto-calibration refuses an orientation-poor recording", {
  fs <- 30
  win <- 10 * fs
  set.seed(3)
  # 15 still windows all at the +z orientation (no sphere coverage)
  raw <- do.call(rbind, lapply(1:15, function(k) {
    matrix(rep(c(0, 0, 1), each = win), win, 3) +
      matrix(stats::rnorm(win * 3, 0, 0.003), win, 3)
  }))
  expect_error(autoCalibrateAccel(raw, fs),
               "span the unit sphere|implausible")
})

test_that("detectNonWear (sliding) finds a non-wear period across a boundary", {
  fs <- 10
  set.seed(4)
  half <- fs * 60 * 15                                    # 15 min
  tt <- seq_len(half) / fs
  move <- cbind(0.4 * sin(2 * pi * 1.5 * tt), 0.3 * cos(2 * pi * 1.5 * tt),
                1 + 0.4 * sin(2 * pi * 1.5 * tt))
  still <- matrix(rep(c(0, 0, 1), each = fs * 60 * 30), ncol = 3) +
    matrix(stats::rnorm(fs * 60 * 30 * 3, 0, 0.001), ncol = 3)
  # 15 min move, 30 min still (straddles the 30-min block boundary), 15 min move
  sig <- rbind(move, still, move)
  nw <- detectNonWear(sig, fs, window_min = 30)
  expect_gt(nw$nonwear_fraction, 0.2)                    # the still block found
})

test_that("computeENMO errors when the epoch is longer than the signal", {
  expect_error(computeENMO(matrix(0, 50, 3), sampling_rate = 10,
                           epoch_sec = 100), "longer than the signal")
})
