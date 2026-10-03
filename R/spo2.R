# Pulse-oximetry (SpO2) analysis.
#
# Summarises a blood-oxygen series (e.g. Apple Watch OxygenSaturation, from an
# Apple Health export) into the standard oximetry indices: mean, nadir, time
# below 90% (T90/CT90), and an oxygen desaturation index (ODI). NOTE: the Apple
# Watch records SpO2 as periodic background spot checks, not a continuous trace,
# so a duration-based T90 and ODI are only clinically meaningful when the input
# is continuous overnight oximetry.

# Count desaturation excursions: runs where SpO2 dips at least `desat` below a
# preceding rolling-max baseline (one event per excursion).
.count_desaturations <- function(x, desat, window) {
  n <- length(x)
  if (n < 3L) return(0L)
  base <- numeric(n)
  for (i in seq_len(n)) base[i] <- max(x[max(1L, i - window):i])
  low <- x <= (base - desat)
  rr <- rle(low)
  sum(rr$values)
}

#' Oximetry (SpO2) metrics
#'
#' Computes the standard blood-oxygen summary indices from an SpO2 series.
#' Accepts SpO2 as a percentage (90) or a fraction (0.90; auto-detected and
#' scaled). When `time` is supplied the time-below-threshold and desaturation
#' index are duration-weighted; otherwise they are sample proportions/counts.
#'
#' @param spo2 Numeric SpO2 series (percent or 0-1 fraction).
#' @param time Optional sample times as `POSIXct` or numeric seconds (same length
#'   and order as `spo2`). Enables `t90_min` and per-hour `odi`.
#' @param threshold Desaturation threshold percent for T90/CT90 (default 90).
#' @param desat Drop (percentage points) below the rolling baseline that defines
#'   a desaturation event (default 3; 4 is also common).
#' @param window Rolling-baseline length in samples for event detection (default 12).
#' @return An `spo2_metrics` object: `mean`, `nadir`, `pct_below`, `ct90`,
#'   `t90_min`, `n_desat`, `odi` (events/hour), plus the settings.
#' @references Chung F et al. (2012) oximetry desaturation indices; standard
#'   ODI/CT90 definitions used in sleep-disordered-breathing screening.
#' @seealso [summarizeAppleSleep()]
#' @export
#' @examples
#' set.seed(1)
#' spo2 <- pmin(100, pmax(80, 97 + round(rnorm(200))))
#' spo2[50:55] <- 88   # a desaturation
#' spo2Metrics(spo2)
spo2Metrics <- function(spo2, time = NULL, threshold = 90, desat = 3, window = 12) {
  x <- as.numeric(spo2)
  keep <- !is.na(x)
  x <- x[keep]
  if (!length(x)) stop("`spo2` has no non-missing values.", call. = FALSE)
  if (max(x) <= 1) x <- x * 100                      # fraction -> percent
  below <- x < threshold

  if (!is.null(time)) {
    tt <- as.numeric(time)[keep]
    o <- order(tt); tt <- tt[o]; x2 <- x[o]; below2 <- x2 < threshold
    d <- diff(tt)
    dt <- c(d, if (length(d)) stats::median(d) else 0)
    span_h <- (max(tt) - min(tt)) / 3600
    t90_min <- sum(dt[below2]) / 60
    ct90 <- if (sum(dt) > 0) 100 * sum(dt[below2]) / sum(dt) else NA_real_
    ev <- .count_desaturations(x2, desat, window)
    odi <- if (!is.na(span_h) && span_h > 0) ev / span_h else NA_real_
  } else {
    span_h <- NA_real_; t90_min <- NA_real_
    ct90 <- 100 * mean(below)
    ev <- .count_desaturations(x, desat, window)
    odi <- NA_real_
  }

  structure(list(mean = mean(x), nadir = min(x), pct_below = 100 * mean(below),
                 ct90 = ct90, t90_min = t90_min, n_desat = ev, odi = odi,
                 threshold = threshold, desat = desat, n = length(x),
                 continuous = !is.null(time)),
            class = "spo2_metrics")
}

#' @export
print.spo2_metrics <- function(x, ...) {
  cat(sprintf("<spo2_metrics> n=%d  mean=%.1f%%  nadir=%.1f%%\n", x$n, x$mean, x$nadir))
  cat(sprintf("  <%g%%: %.1f%% of samples%s\n", x$threshold, x$pct_below,
              if (!is.na(x$t90_min)) sprintf("  (T90 %.1f min, CT90 %.1f%%)", x$t90_min, x$ct90) else ""))
  cat(sprintf("  desaturations (>=%g pt): %d%s\n", x$desat, x$n_desat,
              if (!is.na(x$odi)) sprintf("  (ODI %.1f/h)", x$odi) else ""))
  if (!isTRUE(x$continuous)) {
    cat("  note: no timing supplied (or Apple Watch spot checks) -> ODI/T90 unavailable or approximate\n")
  }
  invisible(x)
}
