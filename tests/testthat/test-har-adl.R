# HAR for ADL: windowed features, activity recognition and ICF mapping.

# synthetic activity signal (n x 3 accel, g): distinct orientation/frequency.
gen_activity <- function(act, secs = 40, fs = 20, seed = 1) {
  set.seed(seed)
  t <- seq(0, secs, 1 / fs); n <- length(t); nz <- function(s) rnorm(n, 0, s)
  switch(act,
    walking  = cbind(0.2 * sin(2 * pi * 1.8 * t) + nz(0.02),
                     0.2 * cos(2 * pi * 1.8 * t) + nz(0.02), 1 + nz(0.02)),
    running  = cbind(0.6 * sin(2 * pi * 3.1 * t) + nz(0.05),
                     0.6 * cos(2 * pi * 3.1 * t) + nz(0.05), 1 + nz(0.05)),
    sitting  = cbind(nz(0.01), 0.5 + nz(0.01), 0.87 + nz(0.01)),  # leaned trunk
    standing = cbind(nz(0.01), nz(0.01), 1 + nz(0.01)))           # upright
}

test_that("adlFeatures produces one row per window with sensible values", {
  fs <- 20
  static <- cbind(rnorm(400, 0, 0.005), rnorm(400, 0, 0.005), 1)
  # magnitude oscillation so the vector magnitude carries a clean 2 Hz tone
  # (a single-axis sinusoid around gravity would alias to 2x in |a|)
  osc <- cbind(0, 0, 1 + 0.3 * sin(2 * pi * 2 * seq(0, 20, 1 / fs)))
  fst <- adlFeatures(static, fs, window_sec = 2.56, overlap = 0.5)
  fos <- adlFeatures(osc, fs, window_sec = 2.56, overlap = 0.5)
  # static window: near-zero vm variability; oscillating: higher and a clear tone
  expect_lt(mean(fst$vm_sd), 0.02)
  expect_gt(mean(fos$vm_sd), mean(fst$vm_sd))
  expect_equal(median(fos$dom_freq), 2, tolerance = 0.4)   # recovers 2 Hz
  # window count matches the hop
  win_n <- round(2.56 * fs); step <- round(win_n * 0.5)
  expect_equal(nrow(fst), length(seq(1, 400 - win_n + 1, by = step)))
})

test_that("trainADL + recognizeADL classify distinct activities accurately", {
  fs <- 20; acts <- c("walking", "running", "sitting", "standing")
  train <- do.call(rbind, lapply(acts, function(a) {
    f <- adlFeatures(gen_activity(a, seed = 1), fs); f$activity <- a; f
  }))
  m <- trainADL(train[, setdiff(names(train), "activity")], train$activity)
  expect_s3_class(m, "adl_model")
  expect_setequal(levels(m$ytr), acts)

  # held-out recordings (different noise)
  acc_test <- 0
  for (a in acts) {
    r <- recognizeADL(m, gen_activity(a, seed = 99), fs)
    acc_test <- acc_test + mean(r$activity == a)
  }
  expect_gt(acc_test / length(acts), 0.9)          # mean per-activity accuracy
})

test_that("adlBudget and adlToICF summarise and map to ICF performance", {
  recognized <- data.frame(
    window = 1:6, start_sec = (0:5) * 1.28, end_sec = (0:5) * 1.28 + 2.56,
    activity = c("walking", "walking", "sitting", "sitting", "sitting",
                 "eating"), stringsAsFactors = FALSE)
  b <- adlBudget(recognized)
  expect_equal(b$activity[1], "sitting")           # most windows
  expect_equal(sum(b$n_windows), 6)
  expect_equal(sum(b$proportion), 1)

  icf <- adlToICF(recognized)
  expect_true(all(icf$qualifier == "performance"))
  expect_equal(icf$icf_code[icf$icf_title == "Walking"], "d450")
  expect_true("d415" %in% icf$icf_code)            # sitting -> maintaining posture
  expect_true("d550" %in% icf$icf_code)            # eating -> d550
  # proportions across ICF codes still sum to 1
  expect_equal(sum(icf$proportion), 1, tolerance = 1e-8)
})

test_that("adlToICF maps the self-care activities to their d5 codes", {
  m <- adlToICF(c("washing", "toileting", "grooming", "dressing", "eating",
                  "drinking"))
  expect_equal(m$icf_code[m$icf_title == "Washing oneself"], "d510")
  expect_equal(m$icf_code[m$icf_title == "Toileting"], "d530")
  expect_equal(m$icf_code[m$icf_title == "Caring for body parts"], "d520")
  expect_true(all(m$qualifier == "performance"))
})

test_that("adlToICF warns on unmapped activities and predict guards features", {
  expect_warning(adlToICF(c("walking", "moon_walk")), "no ICF map")
  fs <- 20
  m <- trainADL(
    { f <- adlFeatures(gen_activity("walking", seed = 1), fs); f },
    rep("walking", nrow(adlFeatures(gen_activity("walking", seed = 1), fs))))
  expect_error(predict(m, data.frame(x_mean = 1)), "missing feature")
})
