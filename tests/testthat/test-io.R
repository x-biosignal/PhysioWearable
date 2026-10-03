library(testthat)
library(PhysioWearable)

test_that("accelToPhysioExperiment builds a PhysioExperiment", {
  skip_if_not_installed("PhysioCore")
  skip_if_not_installed("S4Vectors")
  skip_if_not_installed("SummarizedExperiment")
  set.seed(1)
  acc <- cbind(stats::rnorm(300, 0, 0.1), stats::rnorm(300, 0, 0.1),
               1 + stats::rnorm(300, 0, 0.1))
  pe <- accelToPhysioExperiment(acc, 30)
  expect_s4_class(pe, "PhysioExperiment")
  a <- SummarizedExperiment::assay(pe, "acceleration")
  expect_equal(dim(a), c(300L, 3L))
  expect_equal(colnames(a), c("x", "y", "z"))
  expect_equal(PhysioCore::samplingRate(pe), 30)
})

test_that("readAccelCSV ingests a tri-axial CSV, auto-detecting x/y/z", {
  skip_if_not_installed("PhysioCore")
  skip_if_not_installed("SummarizedExperiment")
  set.seed(2)
  acc <- cbind(stats::rnorm(200, 0, 0.1), stats::rnorm(200, 0, 0.1),
               1 + stats::rnorm(200, 0, 0.1))
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(time = seq_len(200), x = acc[, 1], y = acc[, 2],
                              z = acc[, 3]), tmp, row.names = FALSE)
  pe <- readAccelCSV(tmp, 30)
  expect_equal(dim(SummarizedExperiment::assay(pe, "acceleration")),
               c(200L, 3L))
  # explicit column selection also works
  pe2 <- readAccelCSV(tmp, 30, columns = c("x", "y", "z"))
  expect_equal(dim(SummarizedExperiment::assay(pe2, "acceleration")),
               c(200L, 3L))
})

test_that("readAccelCSV errors when x/y/z cannot be resolved", {
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(a = 1:10, b = 1:10, c = 1:10), tmp,
                   row.names = FALSE)
  expect_error(readAccelCSV(tmp, 30), "auto-detect")
  expect_error(readAccelCSV("does_not_exist.csv", 30), "existing CSV")
})
