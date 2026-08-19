test_that("coleKripke scores quiet epochs as sleep and active epochs as wake", {
  set.seed(1)
  counts <- c(rpois(30, 40), rpois(90, 1), rpois(30, 45))   # active | quiet | active
  sw <- coleKripke(counts, rescore = FALSE)
  expect_length(sw, length(counts))
  expect_true(all(sw %in% c(0L, 1L)))
  expect_gt(mean(sw[45:105]), 0.8)      # quiet middle -> mostly sleep
  expect_lt(mean(sw[1:25]), 0.3)        # active start -> mostly wake
})

test_that("summarizeSleep computes standard metrics", {
  sw <- c(rep(0, 5), rep(1, 40), 0, 0, rep(1, 30))          # 5 wake, sleep w/ a 2-min waso
  s <- summarizeSleep(sw, epoch = 60)
  expect_equal(s$tib_min, 72)          # first sleep (idx 6) to last (idx 77) = 72 epochs
  expect_equal(s$tst_min, 70)          # 40 + 30
  expect_equal(s$waso_min, 2)
  expect_equal(s$sol_min, 0)           # period starts at first sleep
  expect_equal(s$n_awakenings, 1L)
  expect_equal(round(s$sleep_efficiency, 3), round(70 / 72, 3))
})

test_that("summarizeAppleSleep turns stages into per-night clinical metrics", {
  t0 <- as.POSIXct("2023-05-01 23:00:00", tz = "UTC")
  stages <- data.frame(
    start = t0 + c(0, 3600, 3720, 7200),
    end   = t0 + c(3600, 3720, 7200, 10800),
    value = c("AsleepCore", "Awake", "AsleepDeep", "AsleepREM"))
  s <- summarizeAppleSleep(stages)
  expect_equal(nrow(s), 1L)
  expect_equal(s$tst_min, 178)
  expect_equal(s$tib_min, 180)
  expect_equal(s$waso_min, 2)
  expect_equal(s$n_awakenings, 1L)
  expect_equal(c(s$core_min, s$deep_min, s$rem_min), c(60, 58, 60))
  expect_equal(round(s$sleep_efficiency, 3), 0.989)
})

test_that("summarizeAppleSleep splits nights on a large gap", {
  t0 <- as.POSIXct("2023-05-01 23:00:00", tz = "UTC")
  stages <- data.frame(
    start = c(t0, t0 + 3600, t0 + 86400, t0 + 90000),        # ~1 day apart
    end   = c(t0 + 3600, t0 + 7200, t0 + 90000, t0 + 93600),
    value = c("AsleepCore", "AsleepREM", "AsleepCore", "AsleepDeep"))
  s <- summarizeAppleSleep(stages)
  expect_equal(nrow(s), 2L)
})
