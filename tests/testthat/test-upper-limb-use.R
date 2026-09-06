# Real-world upper-limb use metrics (upperLimbUse), verified on synthetic
# bilateral streams with known asymmetry (per-epoch ENMO input, mg).

test_that("symmetric arm use gives use ratio 1 and zero magnitude ratio", {
  e <- rep(10, 200)
  r <- upperLimbUse(e, e)
  expect_s3_class(r, "upper_limb_use")
  expect_equal(r$icf_code, "d445")
  expect_equal(r$use_ratio, 1)
  expect_equal(r$magnitude_ratio, 0, tolerance = 1e-6)
  expect_equal(r$laterality_index, 0)
  expect_equal(r$hours_affected, r$hours_unaffected)
})

test_that("use ratio recovers a known active-time asymmetry", {
  unaff <- c(rep(10, 100), rep(0.5, 100))          # active 100 epochs
  aff   <- c(rep(10, 50),  rep(0.5, 150))          # active 50 epochs
  r <- upperLimbUse(aff, unaff)
  expect_equal(r$use_ratio, 0.5)                    # 50 / 100
  expect_lt(r$laterality_index, 0)                  # affected used less
})

test_that("magnitude ratio recovers a known intensity asymmetry", {
  unaff <- rep(20, 200)
  aff   <- rep(6, 200)                              # ~0.3x intensity, both active
  r <- upperLimbUse(aff, unaff)
  expect_equal(r$magnitude_ratio, log(6 / 20), tolerance = 0.01)  # ~ -1.20
  expect_lt(r$magnitude_ratio, 0)                   # unaffected dominant
})

test_that("extreme ratios are capped and hours computed from the epoch length", {
  unaff <- rep(50, 100); aff <- rep(0.5, 100)       # affected inactive
  r <- upperLimbUse(aff, unaff, epoch_sec = 60)
  expect_lte(r$magnitude_ratio, 0)
  expect_gte(r$magnitude_ratio, -7)                 # capped
  expect_equal(r$hours_unaffected, 100 * 60 / 3600) # 100 active min-epochs
  expect_equal(r$hours_affected, 0)
})

test_that("raw accel matrices are accepted (needs sampling rate)", {
  fs <- 20
  active <- cbind(0.3 * sin(2 * pi * 2 * seq(0, 30, 1 / fs)), 0, 1)
  still  <- cbind(0, 0, 1)[rep(1, nrow(active)), ]
  r <- upperLimbUse(active, still, sampling_rate = fs, epoch_sec = 5)
  expect_gt(r$hours_affected, r$hours_unaffected)    # moving arm used more
  expect_error(upperLimbUse(active, still), "sampling_rate")
})
