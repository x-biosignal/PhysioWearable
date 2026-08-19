# Wrist / actigraphy sleep analysis.
#
# Two entry points cover the Apple Watch (and research-actigraphy) sleep use
# cases: `summarizeAppleSleep()` turns the sleep STAGES the watch already scores
# (from an Apple Health export) into clinical sleep metrics, while `coleKripke()`
# scores sleep/wake from raw activity counts when only movement is available.

#' Cole-Kripke actigraphy sleep/wake scoring
#'
#' Scores each epoch as sleep or wake from per-epoch activity counts using the
#' Cole-Kripke algorithm: a weighted sum of the surrounding epochs' activity is
#' thresholded (`D < 1` => sleep). Weights are the classic 1-minute set.
#'
#' @param counts Numeric vector of per-epoch activity counts (one per minute).
#' @param rescore If `TRUE` (default) apply the Webster rescoring rules that flip
#'   short isolated sleep bouts after sustained wake to wake.
#' @return An integer vector the same length as `counts`: `1` = sleep, `0` = wake.
#' @references Cole RJ, Kripke DF, Gruen W, Mullaney DJ, Gillin JC (1992).
#'   "Automatic sleep/wake identification from wrist activity." Sleep 15:461-469.
#' @seealso [summarizeSleep()], [summarizeAppleSleep()]
#' @export
#' @examples
#' set.seed(1)
#' counts <- c(rpois(30, 40), rpois(60, 2), rpois(20, 45))  # active, quiet, active
#' table(coleKripke(counts))
coleKripke <- function(counts, rescore = TRUE) {
  A <- as.numeric(counts)
  if (anyNA(A)) A[is.na(A)] <- 0
  n <- length(A)
  if (n == 0L) return(integer(0))
  w <- c(106, 54, 58, 76, 230, 74, 67)          # weights for lags -4..+2
  pad <- c(0, 0, 0, 0, A, 0, 0)
  D <- 0.001 * (w[1] * pad[1:n]       + w[2] * pad[2:(n + 1)] +
                w[3] * pad[3:(n + 2)] + w[4] * pad[4:(n + 3)] +
                w[5] * pad[5:(n + 4)] + w[6] * pad[6:(n + 5)] +
                w[7] * pad[7:(n + 6)])
  sleep <- as.integer(D < 1)

  if (isTRUE(rescore) && n > 0L) {
    # Webster rule of thumb: after >=10 min of continuous wake, the first minutes
    # scored as sleep are rescored wake (drop the isolated micro-sleep).
    r <- rle(sleep)
    starts <- cumsum(r$lengths) - r$lengths + 1L
    for (i in seq_along(r$values)) {
      if (r$values[i] == 1L && i > 1L && r$values[i - 1L] == 0L &&
          r$lengths[i - 1L] >= 10L) {
        flip <- min(r$lengths[i], if (r$lengths[i - 1L] >= 15L) 4L else 1L)
        sleep[starts[i]:(starts[i] + flip - 1L)] <- 0L
      }
    }
  }
  sleep
}

#' Summarise a sleep/wake series into standard sleep metrics
#'
#' @param sleep_wake Integer/logical per-epoch sleep(1)/wake(0) vector (e.g. from
#'   [coleKripke()]).
#' @param epoch Epoch length in seconds (default 60).
#' @param spt Optional integer length-2 vector `c(start, end)` of epoch indices
#'   bounding the sleep-period (time in bed). If `NULL` (default) it spans the
#'   first to the last sleep epoch.
#' @return A one-row data frame: `tib_min` (time in bed), `tst_min` (total sleep
#'   time), `sleep_efficiency` (TST/TIB), `waso_min` (wake after sleep onset),
#'   `sol_min` (sleep-onset latency), `n_awakenings`.
#' @seealso [coleKripke()]
#' @export
#' @examples
#' sw <- c(rep(0, 5), rep(1, 40), 0, 0, rep(1, 30))
#' summarizeSleep(sw)
summarizeSleep <- function(sleep_wake, epoch = 60, spt = NULL) {
  s <- as.integer(sleep_wake != 0)
  n <- length(s)
  if (n == 0L || !any(s == 1L)) {
    return(data.frame(tib_min = 0, tst_min = 0, sleep_efficiency = NA_real_,
                      waso_min = 0, sol_min = NA_real_, n_awakenings = 0L))
  }
  asleep <- which(s == 1L)
  if (is.null(spt)) spt <- c(min(asleep), max(asleep))
  win <- seq(spt[1], spt[2])
  emin <- epoch / 60

  sw <- s[win]
  tib_min <- length(win) * emin
  tst_min <- sum(sw == 1L) * emin
  waso_min <- sum(sw == 0L) * emin                    # wake within the period
  sol_min <- (which(sw == 1L)[1] - 1L) * emin         # from period start to first sleep
  # awakenings: wake runs inside the period (excluding a trailing wake tail)
  r <- rle(sw)
  wake_runs <- sum(r$values == 0L)
  if (length(r$values) && r$values[length(r$values)] == 0L) wake_runs <- wake_runs - 1L
  if (length(r$values) && r$values[1] == 0L) wake_runs <- wake_runs - 1L  # leading = latency
  n_awak <- max(0L, wake_runs)

  data.frame(tib_min = tib_min, tst_min = tst_min,
             sleep_efficiency = tst_min / tib_min,
             waso_min = waso_min, sol_min = sol_min, n_awakenings = n_awak)
}

#' Summarise staged sleep into per-night clinical metrics
#'
#' Vendor-agnostic engine behind [summarizeAppleSleep()]: given sleep-stage
#' intervals labelled by any scheme (Apple `AsleepCore/Deep/REM`, Fitbit
#' `light/deep/rem/wake`, ...), compute per-night sleep metrics. Consecutive
#' intervals are grouped into nights whenever the gap between them exceeds
#' `gap_min`.
#'
#' @param stages A data frame with `start`, `end` (`POSIXct`) and a stage-label
#'   column named `value` or `stage`.
#' @param asleep_levels Labels counted as asleep (e.g. Apple
#'   `c("AsleepCore","AsleepDeep","AsleepREM")`; Fitbit `c("light","deep","rem")`).
#' @param wake_levels Labels counted as wake within the sleep period (default
#'   `"Awake"`; Fitbit `"wake"`).
#' @param inbed_levels Labels counted as explicit time in bed (default `"InBed"`).
#' @param stage_cols Optional named character vector mapping output columns to
#'   stage labels, e.g. `c(deep = "deep", rem = "rem")` adds `deep_min`, `rem_min`.
#' @param gap_min Minutes of gap that start a new night (default 120).
#' @return A data frame, one row per night: `night`, `start`, `end`, `tib_min`,
#'   `tst_min`, `sleep_efficiency`, `waso_min`, `sol_min`, `n_awakenings`, and one
#'   `<name>_min` column per `stage_cols` entry.
#' @seealso [summarizeAppleSleep()], [summarizeSleep()], [coleKripke()]
#' @export
#' @examples
#' t0 <- as.POSIXct("2023-05-01 23:00:00", tz = "UTC")
#' stages <- data.frame(start = t0 + c(0, 3600, 7200),
#'                      end = t0 + c(3600, 7200, 10800),
#'                      stage = c("light", "deep", "rem"))
#' summarizeSleepStages(stages, asleep_levels = c("light", "deep", "rem"),
#'                      wake_levels = "wake", stage_cols = c(deep = "deep", rem = "rem"))
summarizeSleepStages <- function(stages, asleep_levels, wake_levels = "Awake",
                                 inbed_levels = "InBed", stage_cols = NULL,
                                 gap_min = 120) {
  if (!all(c("start", "end") %in% names(stages))) {
    stop("`stages` needs `start` and `end` columns.", call. = FALSE)
  }
  lbl_col <- if ("value" %in% names(stages)) "value" else
    if ("stage" %in% names(stages)) "stage" else
      stop("`stages` needs a `value` or `stage` label column.", call. = FALSE)
  if (!nrow(stages)) return(data.frame())
  o <- order(stages$start)
  st <- stages[o, , drop = FALSE]
  # match stage labels case-insensitively so a vendor's "awake"/"Awake"/"AWAKE"
  # all satisfy the default level sets (Apple uses "Awake", Health Connect "awake").
  lbl <- tolower(as.character(st[[lbl_col]]))
  asleep_levels <- tolower(asleep_levels)
  wake_levels <- tolower(wake_levels)
  inbed_levels <- tolower(inbed_levels)
  dur <- as.numeric(difftime(st$end, st$start, units = "mins"))

  gap <- as.numeric(difftime(st$start[-1], st$end[-nrow(st)], units = "mins"))
  night <- cumsum(c(0L, as.integer(gap > gap_min))) + 1L
  is_asleep <- lbl %in% asleep_levels

  do.call(rbind, lapply(sort(unique(night)), function(g) {
    k <- night == g
    d <- dur[k]; v <- lbl[k]; a <- is_asleep[k]
    asleep_idx <- which(a)
    tst <- sum(d[a])
    inbed <- sum(d[v %in% inbed_levels])
    span <- as.numeric(difftime(max(st$end[k]), min(st$start[k]), units = "mins"))
    tib <- if (inbed > 0) inbed else span
    if (length(asleep_idx)) {
      inner <- seq(min(asleep_idx), max(asleep_idx))
      waso <- sum(d[inner][v[inner] %in% wake_levels])
      sol <- sum(d[seq_len(min(asleep_idx) - 1L)])
      n_awak <- sum(rle(v[inner] %in% wake_levels)$values)
    } else { waso <- 0; sol <- NA_real_; n_awak <- 0L }
    row <- data.frame(night = g, start = min(st$start[k]), end = max(st$end[k]),
                      tib_min = round(tib, 1), tst_min = round(tst, 1),
                      sleep_efficiency = if (tib > 0) round(tst / tib, 3) else NA_real_,
                      waso_min = round(waso, 1), sol_min = round(sol, 1),
                      n_awakenings = as.integer(n_awak))
    for (nm in names(stage_cols)) {
      row[[paste0(nm, "_min")]] <- round(sum(d[v == tolower(stage_cols[[nm]])]), 1)
    }
    row
  }))
}

#' Summarise Apple Watch sleep stages into clinical metrics
#'
#' Apple-specific wrapper around [summarizeSleepStages()] for the `SleepAnalysis`
#' stage intervals the Apple Watch records (from
#' `PhysioDevices::appleHealthSeries(x, "SleepAnalysis")`): asleep is
#' `AsleepCore/Deep/REM`, and `core_min`/`deep_min`/`rem_min` are reported.
#'
#' @param stages A data frame with `start`, `end` (`POSIXct`) and `value`
#'   (`"AsleepCore"`, `"AsleepDeep"`, `"AsleepREM"`, `"Awake"`, `"InBed"`).
#' @param gap_min Minutes of gap that start a new night (default 120).
#' @return See [summarizeSleepStages()]; with `core_min`/`deep_min`/`rem_min`.
#' @seealso [summarizeSleepStages()], [summarizeSleep()]
#' @export
#' @examples
#' t0 <- as.POSIXct("2023-05-01 23:00:00", tz = "UTC")
#' stages <- data.frame(
#'   start = t0 + c(0, 3600, 3720, 7200),
#'   end   = t0 + c(3600, 3720, 7200, 10800),
#'   value = c("AsleepCore", "Awake", "AsleepDeep", "AsleepREM"))
#' summarizeAppleSleep(stages)
summarizeAppleSleep <- function(stages, gap_min = 120) {
  summarizeSleepStages(
    stages,
    asleep_levels = c("AsleepCore", "AsleepDeep", "AsleepREM",
                      "AsleepUnspecified", "Asleep"),
    wake_levels = "Awake", inbed_levels = "InBed",
    stage_cols = c(core = "AsleepCore", deep = "AsleepDeep", rem = "AsleepREM"),
    gap_min = gap_min)
}
