# Gravity-based accelerometer auto-calibration (van Hees et al. 2014) and
# non-wear detection (van Hees et al. 2011).

#' Gravity-based accelerometer auto-calibration
#'
#' Estimates a per-axis gain and offset that force the acceleration magnitude to
#' 1 g during still periods, following the GGIR sphere-fitting method (van Hees
#' et al. 2014). Still (non-movement) windows are identified by a low per-axis
#' standard deviation; their mean orientations lie on a unit sphere in an
#' ideally-calibrated device, and the gain/offset are fitted by iteratively
#' projecting onto that sphere. Correction is `(accel - offset) * scale`.
#'
#' @param accel An n x 3 matrix of acceleration in g units.
#' @param sampling_rate Sampling rate in Hz.
#' @param window_sec Still-window length in seconds (default 10).
#' @param still_sd Per-axis standard-deviation threshold for a still window
#'   (default 0.013 g).
#' @param min_still Minimum number of still windows required (default 10).
#' @param max_iter,tol Iteration cap and convergence tolerance.
#'
#' @return An `accel_calibration` list with `scale`, `offset`, `residual` (RMS of
#'   the still-point magnitude error after calibration), `n_still`,
#'   `iterations`, `converged`, and a `calibrate()` function that applies the
#'   correction to an n x 3 matrix.
#' @references van Hees VT, et al. (2014). J Appl Physiol 117(7):738-744.
#' @seealso [computeENMO()]
#' @export
autoCalibrateAccel <- function(accel, sampling_rate, window_sec = 10,
                               still_sd = 0.013, min_still = 10,
                               max_iter = 100L, tol = 1e-6) {
  m <- .accel_matrix(accel)
  if (!is.numeric(sampling_rate) || length(sampling_rate) != 1L ||
      !is.finite(sampling_rate) || sampling_rate <= 0) {
    stop("`sampling_rate` must be a single positive number.", call. = FALSE)
  }
  win <- max(1L, as.integer(round(window_sec * sampling_rate)))
  n_win <- nrow(m) %/% win
  if (n_win < 1L) {
    stop("signal shorter than one calibration window.", call. = FALSE)
  }

  means <- matrix(0, n_win, 3)
  sds <- matrix(0, n_win, 3)
  for (w in seq_len(n_win)) {
    idx <- ((w - 1L) * win + 1L):(w * win)
    seg <- m[idx, , drop = FALSE]
    means[w, ] <- colMeans(seg)
    sds[w, ] <- apply(seg, 2, stats::sd)
  }
  still <- rowSums(sds < still_sd) == 3L
  D <- means[still, , drop = FALSE]
  if (nrow(D) < min_still) {
    stop(sprintf(paste0("only %d still windows found (need %d); the recording ",
                        "lacks enough non-movement periods to calibrate."),
                 nrow(D), min_still), call. = FALSE)
  }
  # GGIR sphere-coverage requirement: still orientations must span each axis in
  # both directions, else the per-axis fit is under-determined and would return
  # a garbage calibration with a near-zero (by-construction) residual.
  cov_thresh <- 0.3
  covered <- all(vapply(1:3, function(k) {
    max(D[, k]) > cov_thresh && min(D[, k]) < -cov_thresh
  }, logical(1)))
  if (!covered) {
    stop("still periods do not span the unit sphere in all axes; the sensor ",
         "orientation is too constant to calibrate this recording reliably.",
         call. = FALSE)
  }

  offset <- c(0, 0, 0)
  scale <- c(1, 1, 1)
  iterations <- 0L
  for (it in seq_len(max_iter)) {
    iterations <- it
    cur <- sweep(sweep(D, 2, offset), 2, scale, "*")   # (D - offset) * scale
    r <- sqrt(rowSums(cur^2))
    if (any(r == 0)) break
    target <- cur / r                                  # closest unit-sphere pt
    change <- 0
    for (k in 1:3) {
      fit <- stats::lm(target[, k] ~ cur[, k])
      b <- stats::coef(fit)[1]
      a <- stats::coef(fit)[2]
      if (!is.finite(a) || a == 0) next
      new_scale <- a * scale[k]
      new_offset <- offset[k] - b / (a * scale[k])
      change <- change + (new_scale - scale[k])^2 + (new_offset - offset[k])^2
      scale[k] <- new_scale
      offset[k] <- new_offset
    }
    if (sqrt(change) < tol) break
  }

  # physical-plausibility gate: a real sensor mis-calibration is small; values
  # outside this range signal an under-determined (unreliable) fit.
  if (any(abs(scale - 1) > 0.3) || any(abs(offset) > 0.3)) {
    stop("calibration produced implausible gains/offsets (still periods are ",
         "likely under-determined); recording cannot be calibrated reliably.",
         call. = FALSE)
  }

  cor_still <- sweep(sweep(D, 2, offset), 2, scale, "*")
  residual <- sqrt(mean((sqrt(rowSums(cor_still^2)) - 1)^2))

  calibrate <- function(x) {
    x <- .accel_matrix(x)
    sweep(sweep(x, 2, offset), 2, scale, "*")
  }

  out <- list(
    scale = scale, offset = offset, residual = residual, n_still = nrow(D),
    iterations = iterations, converged = iterations < max_iter,
    calibrate = calibrate
  )
  class(out) <- "accel_calibration"
  out
}

#' Detect non-wear periods
#'
#' Flags non-wear windows where the accelerometer is stationary: at least
#' `min_axes` of the three axes have a low standard deviation and value range
#' over a long window (van Hees et al. 2011).
#'
#' @param accel An n x 3 matrix of acceleration in g units.
#' @param sampling_rate Sampling rate in Hz.
#' @param window_min Window length in minutes (default 60).
#' @param step_min Window step in minutes; `NULL` uses `window_min / 4`. A
#'   sliding (overlapping) window prevents a non-wear period from being diluted
#'   across a block boundary.
#' @param sd_thresh Per-axis standard-deviation threshold (default 0.013 g).
#' @param range_thresh Per-axis value-range threshold (default 0.050 g).
#' @param min_axes Number of axes that must meet both criteria (default 2).
#'
#' @return A `nonwear` list with a per-window `windows` data frame
#'   (`window`, `start_time`, `end_time`, `nonwear`) and the `nonwear_fraction`
#'   (fraction of samples covered by any non-wear window).
#' @references van Hees VT, et al. (2011). PLoS ONE 6(7):e22922.
#' @export
detectNonWear <- function(accel, sampling_rate, window_min = 60,
                          step_min = NULL, sd_thresh = 0.013,
                          range_thresh = 0.050, min_axes = 2L) {
  m <- .accel_matrix(accel)
  if (!is.numeric(sampling_rate) || length(sampling_rate) != 1L ||
      !is.finite(sampling_rate) || sampling_rate <= 0) {
    stop("`sampling_rate` must be a single positive number.", call. = FALSE)
  }
  win <- max(1L, as.integer(round(window_min * 60 * sampling_rate)))
  step <- if (is.null(step_min)) {
    max(1L, as.integer(round(window_min / 4 * 60 * sampling_rate)))
  } else {
    max(1L, as.integer(round(step_min * 60 * sampling_rate)))
  }
  n <- nrow(m)
  if (n < win) {
    stop("signal shorter than one non-wear window.", call. = FALSE)
  }

  starts <- seq(1L, n - win + 1L, by = step)
  nonwear <- logical(length(starts))
  covered <- logical(n)
  for (w in seq_along(starts)) {
    idx <- starts[w]:(starts[w] + win - 1L)
    seg <- m[idx, , drop = FALSE]
    sd_k <- apply(seg, 2, stats::sd)
    range_k <- apply(seg, 2, function(v) diff(range(v)))
    meets <- (sd_k < sd_thresh) & (range_k < range_thresh)
    nonwear[w] <- sum(meets) >= min_axes
    if (nonwear[w]) covered[idx] <- TRUE
  }

  windows <- data.frame(
    window = seq_along(starts),
    start_time = (starts - 1L) / sampling_rate,
    end_time = (starts + win - 1L) / sampling_rate,
    nonwear = nonwear, stringsAsFactors = FALSE
  )
  out <- list(windows = windows, nonwear_fraction = mean(covered),
              window_min = window_min)
  class(out) <- "nonwear"
  out
}

#' @export
print.accel_calibration <- function(x, ...) {
  cat("<accel_calibration>\n")
  cat(sprintf("  scale : %.4f %.4f %.4f\n", x$scale[1], x$scale[2], x$scale[3]))
  cat(sprintf("  offset: %.4f %.4f %.4f\n",
              x$offset[1], x$offset[2], x$offset[3]))
  cat(sprintf("  residual: %.5f g (%d still windows, %d iters, converged %s)\n",
              x$residual, x$n_still, x$iterations, x$converged))
  invisible(x)
}

#' @export
print.nonwear <- function(x, ...) {
  cat(sprintf("<nonwear> %d windows (%g min each), non-wear %.1f%%\n",
              nrow(x$windows), x$window_min, 100 * x$nonwear_fraction))
  invisible(x)
}
