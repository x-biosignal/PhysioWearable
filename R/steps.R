# Step detection from raw tri-axial acceleration.

#' Detect steps from tri-axial acceleration
#'
#' Counts steps by peak-detecting the dynamic acceleration magnitude (vector
#' magnitude minus gravity). Peaks must exceed a prominence threshold and be
#' separated by at least the shortest plausible step interval
#' (`1 / max_step_hz`), which suppresses double counts.
#'
#' @param accel An n x 3 matrix of acceleration in g units, or a numeric vector
#'   already representing an acceleration magnitude.
#' @param sampling_rate Sampling rate in Hz.
#' @param min_step_hz,max_step_hz Plausible step-frequency range in Hz
#'   (defaults 0.5 and 4).
#' @param threshold Minimum peak height in the dynamic magnitude (g). `NULL`
#'   uses `max(0.5 * sd(dynamic magnitude), min_amplitude)`; the absolute floor
#'   stops sensor noise in a still recording from being counted as steps.
#' @param min_amplitude Absolute floor (g) for the automatic threshold
#'   (default 0.05).
#'
#' @return A `wearable_steps` list with `n_steps`, `step_index` (sample indices
#'   of detected steps), and `cadence_spm` (steps per minute).
#' @references Any peak-based pedometer (e.g. Zijlstra & Hof 2003).
#' @seealso [computeENMO()]
#' @export
#' @examples
#' fs <- 50; t <- seq(0, 10, 1 / fs)
#' walk <- cbind(0, 0, 1 + 0.4 * sin(2 * pi * 1.8 * t))  # 1.8 steps/s
#' detectSteps(walk, fs)$n_steps
detectSteps <- function(accel, sampling_rate, min_step_hz = 0.5,
                        max_step_hz = 4, threshold = NULL,
                        min_amplitude = 0.05) {
  if (is.numeric(accel) && is.null(dim(accel))) {
    vm <- as.numeric(accel)
    if (any(!is.finite(vm))) {
      stop("`accel` contains non-finite values.", call. = FALSE)
    }
  } else {
    m <- .accel_matrix(accel)
    vm <- sqrt(rowSums(m^2))
  }
  if (!is.numeric(sampling_rate) || length(sampling_rate) != 1L ||
      !is.finite(sampling_rate) || sampling_rate <= 0) {
    stop("`sampling_rate` must be a single positive number.", call. = FALSE)
  }
  if (!is.numeric(max_step_hz) || max_step_hz <= 0 ||
      !is.numeric(min_step_hz) || min_step_hz <= 0 ||
      min_step_hz >= max_step_hz) {
    stop("require 0 < min_step_hz < max_step_hz.", call. = FALSE)
  }

  if (!is.numeric(min_amplitude) || length(min_amplitude) != 1L ||
      !is.finite(min_amplitude) || min_amplitude < 0) {
    stop("`min_amplitude` must be a single non-negative number.", call. = FALSE)
  }
  dyn <- vm - mean(vm)
  if (is.null(threshold)) {
    threshold <- max(0.5 * stats::sd(dyn), min_amplitude)
  } else if (!is.numeric(threshold) || length(threshold) != 1L ||
             !is.finite(threshold) || threshold < 0) {
    stop("`threshold` must be a single non-negative number (or NULL).",
         call. = FALSE)
  }
  min_dist <- max(1L, as.integer(round(sampling_rate / max_step_hz)))

  idx <- .wear_peaks(dyn, threshold, min_dist)
  n <- length(idx)
  duration_min <- length(vm) / sampling_rate / 60
  cadence <- if (duration_min > 0) n / duration_min else NA_real_

  out <- list(n_steps = n, step_index = idx, cadence_spm = cadence)
  class(out) <- "wearable_steps"
  out
}

#' Local maxima above a threshold, greedily thinned to a minimum spacing
#' @keywords internal
#' @noRd
.wear_peaks <- function(x, threshold, min_dist) {
  n <- length(x)
  if (n < 3L) {
    return(integer(0))
  }
  cand <- which(x[2:(n - 1L)] > x[1:(n - 2L)] &
                  x[2:(n - 1L)] >= x[3:n] &
                  x[2:(n - 1L)] > threshold) + 1L
  if (length(cand) == 0L) {
    return(integer(0))
  }
  ord <- cand[order(x[cand], decreasing = TRUE)]
  kept <- integer(0)
  for (p in ord) {
    if (length(kept) == 0L || all(abs(p - kept) >= min_dist)) {
      kept <- c(kept, p)
    }
  }
  sort(kept)
}

#' @export
print.wearable_steps <- function(x, ...) {
  cat(sprintf("<wearable_steps> %d steps (cadence %.1f steps/min)\n",
              x$n_steps, x$cadence_spm))
  invisible(x)
}
