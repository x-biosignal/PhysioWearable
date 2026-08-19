# Free-living physical-behaviour summary: the day-level and person-level metrics
# that published accelerometry research reports, built on the ENMO / intensity
# primitives (computeENMO, classifyBouts). These describe what a person actually
# does across the day in their own environment -- the ICF *performance*
# qualifier, as opposed to the *capacity* measured by a clinic test -- and serve
# both epidemiological (volume, intensity distribution) and rehab / geriatric
# (fragmentation, real-world walking) prior work.
#
# References: Rowlands AV et al. (2018) Med Sci Sports Exerc 50:1323-1332
# (intensity gradient, MX metrics); Chastin SFM et al. (2010) Gait Posture
# 31:82-86 (fragmentation); WHO (2020) physical activity guidelines.

# per-epoch intensity code 1..4 (sedentary/light/moderate/vigorous), same
# cut-point logic as classifyBouts().
.intensity_code <- function(enmo_mg, thresholds) {
  findInterval(enmo_mg, c(thresholds["light"], thresholds["moderate"],
                          thresholds["vigorous"])) + 1L
}

.gini <- function(x) {
  x <- sort(x[is.finite(x) & x >= 0])
  n <- length(x)
  if (n < 2L || sum(x) == 0) return(0)
  sum((2 * seq_len(n) - n - 1) * x) / (n * sum(x))
}

#' Rowlands intensity gradient
#'
#' The intensity gradient summarises the *distribution* of physical-activity
#' intensity across the whole day: the log-log slope of time accumulated against
#' acceleration intensity (Rowlands et al. 2018). A less negative gradient means
#' relatively more time at higher intensities. Unlike a single MVPA cut-point it
#' uses the entire intensity range and is cut-point free.
#'
#' @param enmo_mg Per-epoch ENMO in milli-g.
#' @param epoch_sec Epoch length in seconds.
#' @param bin_width_mg Intensity bin width in mg (default 25).
#' @param max_mg Upper edge of the binned range in mg (default 4000).
#' @return A list with `gradient` (slope), `intercept`, `r_squared`, and the
#'   `bins` data frame (`mid_mg`, `minutes`) used in the regression.
#' @references Rowlands AV, et al. (2018). Med Sci Sports Exerc 50(6):1323-1332.
#' @seealso [mxMetrics()], [summarizeFreeLiving()]
#' @export
#' @examples
#' # a power-law intensity distribution: time proportional to intensity^-2
#' mids <- seq(12.5, 2000, by = 25)
#' minutes <- 1e5 * mids^(-2)
#' enmo <- rep(mids, round(minutes * 2))     # 30 s epochs -> 2 epochs/min
#' round(intensityGradient(enmo, epoch_sec = 30)$gradient, 2)   # ~ -2
intensityGradient <- function(enmo_mg, epoch_sec, bin_width_mg = 25,
                              max_mg = 4000) {
  enmo_mg <- as.numeric(enmo_mg)
  edges <- seq(0, max_mg, by = bin_width_mg)
  mids <- edges[-length(edges)] + bin_width_mg / 2
  bin <- findInterval(enmo_mg, edges, rightmost.closed = TRUE)
  bin <- bin[bin >= 1 & bin <= length(mids)]
  counts <- tabulate(bin, nbins = length(mids))
  minutes <- counts * epoch_sec / 60
  keep <- minutes > 0
  bins <- data.frame(mid_mg = mids, minutes = minutes)
  if (sum(keep) < 2L) {
    return(list(gradient = NA_real_, intercept = NA_real_,
                r_squared = NA_real_, bins = bins))
  }
  fit <- stats::lm(log(minutes[keep]) ~ log(mids[keep]))
  list(gradient = unname(stats::coef(fit)[2]),
       intercept = unname(stats::coef(fit)[1]),
       r_squared = summary(fit)$r.squared, bins = bins)
}

#' MX physical-activity intensity metrics
#'
#' The MX metrics describe the same distribution from the active end: MX is the
#' acceleration (mg) above which a person's most active `X` minutes are
#' accumulated (Rowlands et al. 2018). M60 is the intensity of the most active
#' hour; M120 the most active two hours. Higher MX = more intense peak activity.
#'
#' @param enmo_mg Per-epoch ENMO in milli-g.
#' @param epoch_sec Epoch length in seconds.
#' @param minutes Integer vector of X values (minutes); default
#'   `c(2, 5, 15, 30, 60, 120)`.
#' @return A named numeric vector `Mxx = mg`; `NA` where the recording is shorter
#'   than X minutes.
#' @references Rowlands AV, et al. (2018).
#' @seealso [intensityGradient()], [summarizeFreeLiving()]
#' @export
#' @examples
#' # most-active 60 min all at >= 200 mg
#' enmo <- c(rep(300, 120), rep(20, 2000))   # 30 s epochs -> 120 = 60 min
#' mxMetrics(enmo, epoch_sec = 30, minutes = 60)
mxMetrics <- function(enmo_mg, epoch_sec, minutes = c(2, 5, 15, 30, 60, 120)) {
  s <- sort(as.numeric(enmo_mg), decreasing = TRUE)
  epochs_per_min <- 60 / epoch_sec
  out <- vapply(minutes, function(x) {
    k <- ceiling(x * epochs_per_min)
    if (k > length(s)) NA_real_ else s[k]
  }, numeric(1))
  stats::setNames(out, paste0("M", minutes))
}

#' Physical-activity fragmentation
#'
#' Fragmentation metrics describe how activity and rest are *accumulated* --
#' many short bouts (fragmented) versus few long ones. Reported for both the
#' active and sedentary states: mean bout duration, bout counts, the
#' transition probabilities (active-to-sedentary `astp`, sedentary-to-active
#' `satp`; each the reciprocal of the mean bout length in the origin state,
#' Chastin et al. 2010) and the Gini index of sedentary-bout durations.
#'
#' @param intensity A per-epoch intensity factor (from [classifyBouts()]) or a
#'   logical/0-1 vector marking active epochs (TRUE = active). When a factor is
#'   given, any level other than `"sedentary"` counts as active.
#' @param epoch_sec Epoch length in seconds.
#' @return A list of fragmentation metrics (durations in minutes).
#' @references Chastin SFM, Granat MH (2010). Gait Posture 31(1):82-86.
#' @seealso [summarizeFreeLiving()]
#' @export
#' @examples
#' # alternating 4-epoch active / 6-epoch sedentary blocks
#' act <- rep(rep(c(TRUE, FALSE), c(4, 6)), 5)
#' activityFragmentation(act, epoch_sec = 60)$astp   # 1/4 = 0.25
activityFragmentation <- function(intensity, epoch_sec) {
  active <- if (is.factor(intensity)) as.character(intensity) != "sedentary"
            else as.logical(intensity)
  active[is.na(active)] <- FALSE
  act_runs <- .runs_true(active)$n
  sed_runs <- .runs_true(!active)$n
  mean_or_na <- function(v) if (length(v)) mean(v) else NA_real_
  mean_act <- mean_or_na(act_runs); mean_sed <- mean_or_na(sed_runs)
  list(
    n_active_bouts = length(act_runs),
    n_sedentary_bouts = length(sed_runs),
    mean_active_bout_min = mean_act * epoch_sec / 60,
    mean_sedentary_bout_min = mean_sed * epoch_sec / 60,
    astp = if (is.na(mean_act) || mean_act == 0) NA_real_ else 1 / mean_act,
    satp = if (is.na(mean_sed) || mean_sed == 0) NA_real_ else 1 / mean_sed,
    gini_sedentary = .gini(sed_runs)
  )
}

#' Diurnal activity profile
#'
#' Mean ENMO by hour of day (0-23), averaged over all supplied epochs -- the
#' rest-activity rhythm of free-living behaviour. Requires per-epoch timestamps.
#'
#' @param enmo_mg Per-epoch ENMO in milli-g.
#' @param timestamps Per-epoch `POSIXct` timestamps (same length as `enmo_mg`).
#' @return A list with `hourly` (length-24 mean ENMO by hour), `peak_hour`, and
#'   `morning`/`afternoon`/`evening`/`night` mean ENMO.
#' @seealso [summarizeFreeLiving()]
#' @export
diurnalProfile <- function(enmo_mg, timestamps) {
  if (!inherits(timestamps, "POSIXct")) {
    stop("`timestamps` must be a POSIXct vector.", call. = FALSE)
  }
  if (length(timestamps) != length(enmo_mg)) {
    stop("`timestamps` and `enmo_mg` must have the same length.", call. = FALSE)
  }
  hr <- as.integer(format(timestamps, "%H"))
  hourly <- vapply(0:23, function(h) {
    v <- enmo_mg[hr == h]
    if (length(v)) mean(v) else NA_real_
  }, numeric(1))
  names(hourly) <- as.character(0:23)
  part <- function(hs) mean(hourly[as.character(hs)], na.rm = TRUE)
  list(hourly = hourly,
       peak_hour = if (all(is.na(hourly))) NA_integer_ else
         (0:23)[which.max(replace(hourly, is.na(hourly), -Inf))],
       night = part(c(0:5, 22:23)), morning = part(6:11),
       afternoon = part(12:17), evening = part(18:21))
}

# per-day index groups; timestamps NULL -> one group of everything.
.by_day <- function(timestamps, n) {
  if (is.null(timestamps)) return(list(seq_len(n)))
  split(seq_len(n), as.Date(timestamps))
}

#' Summarise free-living physical behaviour over one or more days
#'
#' The umbrella summary: from multi-day per-epoch ENMO (plus optional timestamps
#' and a wear mask) it computes, per valid day and averaged across valid days,
#' the physical-behaviour metrics that free-living accelerometry studies report
#' -- intensity time-use (sedentary / light / MVPA), activity volume, the
#' Rowlands intensity gradient and MX metrics, activity fragmentation, the
#' diurnal profile and WHO guideline attainment. Only days with enough wear time
#' are counted as valid; non-wear epochs are excluded from the intensity tallies.
#'
#' @param enmo Per-epoch ENMO (see [computeENMO()]).
#' @param epoch_sec Epoch length in seconds.
#' @param timestamps Optional per-epoch `POSIXct` timestamps; when supplied, days
#'   are split on the calendar date and the diurnal profile is computed.
#' @param wear Optional per-epoch logical wear mask (`TRUE` = worn). Default: all
#'   worn.
#' @param enmo_unit Unit of `enmo`: `"mg"` (default) or `"g"`.
#' @param thresholds Intensity cut-points in mg (see [paIntensityThresholds()]).
#' @param valid_wear_hours Minimum wear hours for a day to be valid (default 10).
#' @param steps_per_day Optional numeric vector of steps for each day (in day
#'   order) folded into the per-day table and averages.
#' @param guideline_mvpa_min Weekly MVPA-equivalent minutes for guideline
#'   attainment (default 150; WHO 2020, counting vigorous double).
#' @return A `freeliving_summary` object: `by_day` (per-day data frame),
#'   `aggregate` (means over valid days plus guideline attainment), `diurnal`
#'   (or `NULL`), `n_valid_days` and settings.
#' @references Rowlands (2018); Chastin (2010); WHO (2020).
#' @seealso [intensityGradient()], [mxMetrics()], [activityFragmentation()],
#'   [freeLivingICF()]
#' @export
#' @examples
#' set.seed(1)
#' # one day, 30 s epochs: mostly sedentary with an active hour
#' enmo <- c(rep(5, 2 * 60 * 10), rep(120, 2 * 60), rep(5, 2 * 60 * 12))
#' s <- summarizeFreeLiving(enmo, epoch_sec = 30, valid_wear_hours = 0)
#' s$aggregate$mvpa_min
summarizeFreeLiving <- function(enmo, epoch_sec, timestamps = NULL, wear = NULL,
                                enmo_unit = c("mg", "g"),
                                thresholds = paIntensityThresholds(),
                                valid_wear_hours = 10, steps_per_day = NULL,
                                guideline_mvpa_min = 150) {
  enmo_unit <- match.arg(enmo_unit)
  enmo <- as.numeric(enmo)
  n <- length(enmo)
  if (n < 1L || any(!is.finite(enmo))) {
    stop("`enmo` must be a finite numeric vector.", call. = FALSE)
  }
  enmo_mg <- if (enmo_unit == "g") enmo * 1000 else enmo
  if (is.null(wear)) wear <- rep(TRUE, n)
  wear <- as.logical(wear)
  if (length(wear) != n) stop("`wear` must match `enmo` in length.", call. = FALSE)
  if (!is.null(timestamps) && length(timestamps) != n) {
    stop("`timestamps` must match `enmo` in length.", call. = FALSE)
  }
  if (is.null(names(thresholds)) && length(thresholds) == 3L) {
    names(thresholds) <- c("light", "moderate", "vigorous")
  }

  day_groups <- .by_day(timestamps, n)
  day_labels <- if (is.null(timestamps)) "day1" else names(day_groups)

  per_day <- lapply(seq_along(day_groups), function(di) {
    idx <- day_groups[[di]]
    w <- wear[idx]
    wear_hours <- sum(w) * epoch_sec / 3600
    e <- enmo_mg[idx][w]                       # wear-time ENMO for the day
    if (!length(e)) {
      code <- integer(0)
    } else {
      code <- .intensity_code(e, thresholds)
    }
    min_of <- function(k) sum(code == k) * epoch_sec / 60
    frag <- activityFragmentation(if (length(code)) code >= 2L else logical(0),
                                  epoch_sec)
    ig <- if (length(e) >= 2L) intensityGradient(e, epoch_sec)$gradient else NA_real_
    mx <- if (length(e)) mxMetrics(e, epoch_sec, minutes = c(30, 60)) else
      c(M30 = NA_real_, M60 = NA_real_)
    data.frame(
      day = day_labels[di], wear_hours = wear_hours,
      valid = wear_hours >= valid_wear_hours,
      sedentary_min = min_of(1), light_min = min_of(2),
      moderate_min = min_of(3), vigorous_min = min_of(4),
      mvpa_min = min_of(3) + min_of(4),
      mean_enmo_mg = if (length(e)) mean(e) else NA_real_,
      steps = if (!is.null(steps_per_day)) steps_per_day[di] else NA_real_,
      intensity_gradient = ig, m30_mg = unname(mx["M30"]),
      m60_mg = unname(mx["M60"]),
      astp = frag$astp, satp = frag$satp,
      mean_active_bout_min = frag$mean_active_bout_min,
      mean_sedentary_bout_min = frag$mean_sedentary_bout_min,
      stringsAsFactors = FALSE
    )
  })
  by_day <- do.call(rbind, per_day)

  valid <- by_day[by_day$valid, , drop = FALSE]
  n_valid <- nrow(valid)
  num_cols <- c("wear_hours", "sedentary_min", "light_min", "moderate_min",
                "vigorous_min", "mvpa_min", "mean_enmo_mg", "steps",
                "intensity_gradient", "m30_mg", "m60_mg", "astp", "satp",
                "mean_active_bout_min", "mean_sedentary_bout_min")
  agg <- as.list(stats::setNames(rep(NA_real_, length(num_cols)), num_cols))
  if (n_valid >= 1L) {
    for (cc in num_cols) agg[[cc]] <- mean(valid[[cc]], na.rm = TRUE)
  } else {
    warning("no valid wear day (>= ", valid_wear_hours, " h); ",
            "aggregate is NA.", call. = FALSE)
  }
  weekly_mvpa_equiv <- if (n_valid >= 1L)
    mean(valid$moderate_min + 2 * valid$vigorous_min, na.rm = TRUE) * 7 else NA_real_
  agg$weekly_mvpa_equiv_min <- weekly_mvpa_equiv
  agg$meets_guideline <- isTRUE(weekly_mvpa_equiv >= guideline_mvpa_min)

  diurnal <- if (!is.null(timestamps) && n_valid >= 1L) {
    keep <- unlist(day_groups[by_day$valid], use.names = FALSE)
    keep <- keep[wear[keep]]
    diurnalProfile(enmo_mg[keep], timestamps[keep])
  } else NULL

  out <- list(by_day = by_day, aggregate = agg, diurnal = diurnal,
              n_valid_days = n_valid, epoch_sec = epoch_sec,
              valid_wear_hours = valid_wear_hours,
              guideline_mvpa_min = guideline_mvpa_min)
  class(out) <- "freeliving_summary"
  out
}

#' @export
print.freeliving_summary <- function(x, ...) {
  cat(sprintf("<freeliving_summary> %d day(s), %d valid (>= %g h wear)\n",
              nrow(x$by_day), x$n_valid_days, x$valid_wear_hours))
  a <- x$aggregate
  cat(sprintf("  per valid day: sedentary %.0f / light %.0f / MVPA %.0f min\n",
              a$sedentary_min, a$light_min, a$mvpa_min))
  cat(sprintf("  intensity gradient %.2f | M60 %.0f mg | ASTP %.3f\n",
              a$intensity_gradient, a$m60_mg, a$astp))
  cat(sprintf("  weekly MVPA-equiv %.0f min | meets guideline: %s\n",
              a$weekly_mvpa_equiv_min, if (isTRUE(a$meets_guideline)) "yes" else "no"))
  invisible(x)
}
