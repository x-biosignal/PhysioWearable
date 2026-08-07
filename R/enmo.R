# ENMO acceleration metric, physical-activity intensity classification and
# bout detection (van Hees et al. 2013; Hildebrand et al. 2014 cut-points).

#' Coerce accelerometer input to an n x 3 numeric matrix (g units)
#' @keywords internal
#' @noRd
.accel_matrix <- function(accel, what = "accel") {
  if (is.data.frame(accel)) accel <- as.matrix(accel)
  if (is.numeric(accel) && is.null(dim(accel))) {
    stop(sprintf("`%s` must be an n x 3 matrix (x, y, z).", what), call. = FALSE)
  }
  m <- as.matrix(accel)
  if (!is.numeric(m) || ncol(m) != 3L) {
    stop(sprintf("`%s` must be an n x 3 numeric matrix (x, y, z).", what),
         call. = FALSE)
  }
  if (any(!is.finite(m))) {
    stop(sprintf("`%s` contains non-finite values.", what), call. = FALSE)
  }
  m
}

#' Mean of each non-overlapping epoch (drops a trailing partial epoch)
#' @keywords internal
#' @noRd
.epoch_mean <- function(x, epoch_n) {
  n_ep <- length(x) %/% epoch_n
  if (n_ep < 1L) {
    return(mean(x))
  }
  colMeans(matrix(x[seq_len(n_ep * epoch_n)], nrow = epoch_n))
}

#' Euclidean Norm Minus One (ENMO) acceleration metric
#'
#' ENMO is the vector magnitude of tri-axial acceleration minus one gravity,
#' with negative values truncated to zero (van Hees et al. 2013). For a
#' perfectly still sensor (magnitude 1 g) ENMO is 0; movement raises it. When an
#' epoch length is given, per-epoch mean ENMO is returned.
#'
#' @param accel An n x 3 matrix (or data frame) of acceleration in g units
#'   (columns x, y, z).
#' @param sampling_rate Sampling rate in Hz (required if `epoch_sec` is set).
#' @param epoch_sec Epoch length in seconds for aggregation; `NULL` returns the
#'   per-sample ENMO.
#' @param unit `"g"` (default) or `"mg"` (milli-g).
#'
#' @return A numeric vector of ENMO values (per sample, or per epoch).
#' @references van Hees VT, et al. (2013). PLoS ONE 8(4):e61691.
#' @seealso [classifyBouts()], [autoCalibrateAccel()]
#' @export
#' @examples
#' still <- matrix(rep(c(0, 0, 1), each = 100), ncol = 3)
#' max(computeENMO(still))          # ~ 0 for a static 1 g signal
computeENMO <- function(accel, sampling_rate = NULL, epoch_sec = NULL,
                        unit = c("g", "mg")) {
  unit <- match.arg(unit)
  m <- .accel_matrix(accel)
  vm <- sqrt(rowSums(m^2))
  enmo <- pmax(vm - 1, 0)

  if (!is.null(epoch_sec)) {
    if (is.null(sampling_rate) || !is.numeric(sampling_rate) ||
        length(sampling_rate) != 1L || !is.finite(sampling_rate) ||
        sampling_rate <= 0) {
      stop("`sampling_rate` (a positive number) is required with `epoch_sec`.",
           call. = FALSE)
    }
    epoch_n <- max(1L, as.integer(round(epoch_sec * sampling_rate)))
    if (epoch_n > length(enmo)) {
      stop(sprintf("epoch_sec (%g s) is longer than the signal.", epoch_sec),
           call. = FALSE)
    }
    enmo <- .epoch_mean(enmo, epoch_n)
  }
  if (unit == "mg") enmo <- enmo * 1000
  enmo
}

#' Physical-activity intensity ENMO cut-points
#'
#' Returns the ENMO thresholds (mg) separating physical-activity intensities for
#' adults (Hildebrand et al. 2014 style): the lower bound of light, moderate and
#' vigorous activity.
#'
#' @return A named numeric vector `c(light, moderate, vigorous)` in mg.
#' @references Hildebrand M, et al. (2014). Med Sci Sports Exerc 46(9):1816-1824.
#' @seealso [classifyBouts()]
#' @export
paIntensityThresholds <- function() {
  c(light = 45, moderate = 100, vigorous = 430)
}

#' Classify physical-activity intensity and detect activity bouts
#'
#' Classifies each ENMO epoch into a physical-activity intensity (sedentary,
#' light, moderate, vigorous) and detects contiguous bouts at or above a target
#' intensity lasting at least a minimum duration.
#'
#' @param enmo Per-epoch ENMO values (from [computeENMO()]).
#' @param epoch_sec Epoch length in seconds.
#' @param thresholds Named intensity thresholds in mg (see
#'   [paIntensityThresholds()]).
#' @param enmo_unit Unit of `enmo`: `"mg"` (default) or `"g"`.
#' @param bout_level Minimum intensity for a bout: `"light"`, `"moderate"`
#'   (default) or `"vigorous"`.
#' @param min_bout_min Minimum bout duration in minutes (default 1).
#'
#' @return A `wearable_bouts` list with `intensity` (per-epoch factor), a `bouts`
#'   data frame (`start_epoch`, `end_epoch`, `n_epochs`, `duration_sec`,
#'   `mean_enmo`), and `minutes` per intensity.
#' @references Hildebrand M, et al. (2014).
#' @seealso [computeENMO()], [paIntensityThresholds()]
#' @export
classifyBouts <- function(enmo, epoch_sec, thresholds = paIntensityThresholds(),
                          enmo_unit = c("mg", "g"),
                          bout_level = c("moderate", "light", "vigorous"),
                          min_bout_min = 1) {
  enmo_unit <- match.arg(enmo_unit)
  bout_level <- match.arg(bout_level)
  enmo <- as.numeric(enmo)
  if (length(enmo) < 1L || any(!is.finite(enmo))) {
    stop("`enmo` must be a finite numeric vector.", call. = FALSE)
  }
  if (!is.numeric(epoch_sec) || length(epoch_sec) != 1L || epoch_sec <= 0) {
    stop("`epoch_sec` must be a single positive number.", call. = FALSE)
  }
  if (!is.numeric(min_bout_min) || length(min_bout_min) != 1L ||
      !is.finite(min_bout_min) || min_bout_min < 0) {
    stop("`min_bout_min` must be a single non-negative number.", call. = FALSE)
  }
  if (is.null(names(thresholds)) && length(thresholds) == 3L) {
    names(thresholds) <- c("light", "moderate", "vigorous")
  }
  if (!all(c("light", "moderate", "vigorous") %in% names(thresholds))) {
    stop("`thresholds` must be named light/moderate/vigorous (or a length-3 ",
         "numeric).", call. = FALSE)
  }
  enmo_mg <- if (enmo_unit == "g") enmo * 1000 else enmo

  lev <- c("sedentary", "light", "moderate", "vigorous")
  code <- findInterval(enmo_mg, c(thresholds["light"], thresholds["moderate"],
                                  thresholds["vigorous"])) + 1L
  intensity <- factor(lev[code], levels = lev)

  bout_min_code <- match(bout_level, lev)
  above <- as.integer(code) >= bout_min_code
  min_epochs <- max(1L, as.integer(ceiling(min_bout_min * 60 / epoch_sec)))

  bouts <- .runs_true(above)
  bouts <- bouts[bouts$n >= min_epochs, , drop = FALSE]
  bout_df <- if (nrow(bouts) == 0L) {
    data.frame(start_epoch = integer(0), end_epoch = integer(0),
               n_epochs = integer(0), duration_sec = numeric(0),
               mean_enmo = numeric(0))
  } else {
    data.frame(
      start_epoch = bouts$start, end_epoch = bouts$end, n_epochs = bouts$n,
      duration_sec = bouts$n * epoch_sec,
      mean_enmo = vapply(seq_len(nrow(bouts)), function(i) {
        mean(enmo_mg[bouts$start[i]:bouts$end[i]])
      }, numeric(1)),
      stringsAsFactors = FALSE
    )
  }

  minutes <- vapply(lev, function(l) {
    sum(intensity == l) * epoch_sec / 60
  }, numeric(1))

  out <- list(intensity = intensity, bouts = bout_df, minutes = minutes,
              bout_level = bout_level, min_bout_min = min_bout_min)
  class(out) <- "wearable_bouts"
  out
}

#' Contiguous TRUE runs as a data frame of start/end/length
#' @keywords internal
#' @noRd
.runs_true <- function(mask) {
  n <- length(mask)
  starts <- integer(0); ends <- integer(0)
  i <- 1L
  while (i <= n) {
    if (isTRUE(mask[i])) {
      j <- i
      while (j < n && isTRUE(mask[j + 1L])) j <- j + 1L
      starts <- c(starts, i); ends <- c(ends, j)
      i <- j + 1L
    } else {
      i <- i + 1L
    }
  }
  data.frame(start = starts, end = ends, n = ends - starts + 1L)
}

#' @export
print.wearable_bouts <- function(x, ...) {
  cat("<wearable_bouts>\n")
  cat("  minutes per intensity:\n")
  for (l in names(x$minutes)) {
    cat(sprintf("    %-10s %.1f min\n", l, x$minutes[[l]]))
  }
  cat(sprintf("  bouts (>= %s, >= %g min): %d\n",
              x$bout_level, x$min_bout_min, nrow(x$bouts)))
  invisible(x)
}
