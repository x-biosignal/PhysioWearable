# Free-living physical-behaviour summary: verified against synthetic data with
# known ground truth (exact time-use, a planted power-law intensity gradient, a
# known MX threshold, analytic fragmentation, planted diurnal peak, guideline
# logic and the valid-wear-day rule).

test_that("time-use minutes are recovered exactly from known intensities", {
  # 30 s epochs (2 per min). Plant known minutes per intensity band.
  th <- paIntensityThresholds()                      # light45 / mod100 / vig430
  enmo <- c(rep(10, 2 * 400),    # 400 min sedentary
            rep(60, 2 * 120),    # 120 min light
            rep(150, 2 * 40),    #  40 min moderate
            rep(500, 2 * 20))    #  20 min vigorous
  s <- summarizeFreeLiving(enmo, epoch_sec = 30, valid_wear_hours = 0)
  a <- s$aggregate
  expect_equal(a$sedentary_min, 400)
  expect_equal(a$light_min, 120)
  expect_equal(a$moderate_min, 40)
  expect_equal(a$vigorous_min, 20)
  expect_equal(a$mvpa_min, 60)                        # moderate + vigorous
})

test_that("intensity gradient recovers a planted power-law exponent", {
  mids <- seq(12.5, 2000, by = 25)
  minutes <- 2e5 * mids^(-2.3)                        # time ~ intensity^-2.3
  enmo <- rep(mids, round(minutes * 2))               # 30 s epochs
  ig <- intensityGradient(enmo, epoch_sec = 30)
  expect_equal(ig$gradient, -2.3, tolerance = 0.05)
  # r^2 is capped below 1 only by discretising a continuous power law into
  # integer epoch counts (sparse high-intensity bins); linearity is still strong
  expect_gt(ig$r_squared, 0.98)
})

test_that("MX metrics recover a known peak-intensity threshold", {
  # most active 60 min at 300 mg, rest low; 30 s epochs -> 120 epochs = 60 min
  enmo <- c(rep(300, 120), rep(15, 3000))
  mx <- mxMetrics(enmo, epoch_sec = 30, minutes = c(30, 60))
  expect_equal(unname(mx["M60"]), 300)
  expect_equal(unname(mx["M30"]), 300)
  # asking for more minutes than exist -> NA
  expect_true(is.na(mxMetrics(rep(100, 10), epoch_sec = 30, minutes = 60)["M60"]))
})

test_that("fragmentation transition probabilities are analytic", {
  # alternating 4-epoch active / 6-epoch sedentary, 60 s epochs
  act <- rep(rep(c(TRUE, FALSE), c(4, 6)), 6)
  fr <- activityFragmentation(act, epoch_sec = 60)
  expect_equal(fr$astp, 1 / 4)                        # 1 / mean active bout len
  expect_equal(fr$satp, 1 / 6)                        # 1 / mean sedentary len
  expect_equal(fr$mean_active_bout_min, 4)            # 4 epochs * 60 s
  expect_equal(fr$gini_sedentary, 0)                  # all bouts equal length
})

test_that("diurnal profile peaks in the planted active hours", {
  start <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
  ts <- start + (0:(2 * 60 * 24 - 1)) * 30            # 30 s epochs over 24 h
  hr <- as.integer(format(ts, "%H"))
  enmo <- ifelse(hr %in% 8:10, 200, 10)               # active 08:00-10:59
  dp <- diurnalProfile(enmo, ts)
  expect_true(dp$peak_hour %in% 8:10)
  expect_gt(dp$morning, dp$night)
})

test_that("guideline attainment and valid-day rule behave correctly", {
  # 30 min MVPA/day * 7 = 210 min-equiv/wk >= 150 -> attained
  enmo <- c(rep(10, 2 * 600), rep(150, 2 * 30), rep(10, 2 * 200))
  s <- summarizeFreeLiving(enmo, epoch_sec = 30, valid_wear_hours = 0)
  expect_true(s$aggregate$meets_guideline)

  # a short-wear day is invalid: 5 h wear with valid_wear_hours = 10
  wear <- c(rep(TRUE, 2 * 60 * 5), rep(FALSE, length(enmo) - 2 * 60 * 5))
  s2 <- suppressWarnings(
    summarizeFreeLiving(enmo, epoch_sec = 30, wear = wear, valid_wear_hours = 10))
  expect_equal(s2$n_valid_days, 0)
  expect_true(is.na(s2$aggregate$mvpa_min))
})

test_that("multi-day split and steps folding work with timestamps", {
  start <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
  ts <- start + (0:(2 * 60 * 24 * 2 - 1)) * 30        # two full days, 30 s epochs
  enmo <- rep(60, length(ts))                          # all light
  s <- summarizeFreeLiving(enmo, epoch_sec = 30, timestamps = ts,
                           valid_wear_hours = 10,
                           steps_per_day = c(6000, 8000))
  expect_equal(nrow(s$by_day), 2)
  expect_equal(s$n_valid_days, 2)
  expect_equal(s$aggregate$steps, 7000)               # mean of the two days
  expect_false(is.null(s$diurnal))
})

test_that("freeLivingICF maps metrics with the performance qualifier", {
  m <- freeLivingICF()
  expect_true(all(m$qualifier == "performance"))
  expect_true("d450" %in% m$icf_code[m$metric == "steps_per_day"])
  expect_true("d570" %in% m$icf_code[m$metric == "mvpa_min"])

  enmo <- c(rep(10, 2 * 600), rep(150, 2 * 30))
  s <- summarizeFreeLiving(enmo, epoch_sec = 30, valid_wear_hours = 0)
  linked <- freeLivingICF(s)
  expect_true("value" %in% names(linked))
  expect_equal(linked$value[linked$metric == "mvpa_min"], s$aggregate$mvpa_min)
})
