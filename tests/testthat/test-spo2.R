test_that("spo2Metrics computes mean/nadir/below and desaturations", {
  spo2 <- rep(97, 200)
  spo2[50:55] <- 88          # one desaturation below 90
  spo2[120:123] <- 85        # another
  m <- spo2Metrics(spo2, desat = 3)
  expect_s3_class(m, "spo2_metrics")
  expect_equal(m$nadir, 85)
  expect_equal(round(m$mean, 1), round(mean(spo2), 1))
  expect_equal(m$n_desat, 2L)
  expect_gt(m$pct_below, 0)
  expect_true(is.na(m$odi))   # no timing -> ODI unavailable
})

test_that("spo2Metrics auto-scales a 0-1 fraction to percent", {
  frac <- rep(0.97, 100); frac[40:45] <- 0.86
  m <- spo2Metrics(frac)
  expect_equal(m$nadir, 86)
  expect_lt(m$mean, 100); expect_gt(m$mean, 90)
})

test_that("spo2Metrics uses timing for T90 and ODI when supplied", {
  # 1 Hz for 1 hour; a 5-minute dip below 90
  n <- 3600
  spo2 <- rep(97, n)
  time <- as.POSIXct("2023-05-01 00:00:00", tz = "UTC") + seq_len(n) - 1
  spo2[1000:1300] <- 87      # ~5 min below 90
  m <- spo2Metrics(spo2, time = time, threshold = 90, desat = 3)
  expect_true(m$continuous)
  expect_gt(m$t90_min, 4); expect_lt(m$t90_min, 6)
  expect_gte(m$n_desat, 1L)
  expect_false(is.na(m$odi))
})
