# Real-world upper-limb use from bilateral wrist accelerometry.
#
# The self-care ADLs (eating, dressing, grooming, washing) are performed with the
# arms, so the real-world PERFORMANCE that a clinic capacity test (ARAT, FMA-UE)
# cannot see is captured by how much each arm is actually used across the day.
# Bilateral wrist accelerometry gives the field-standard metrics for this: the
# Use Ratio (how long the affected arm is active relative to the unaffected one),
# the Magnitude Ratio (their relative intensity, the log activity ratio), the
# Bilateral Magnitude (overall arm activity) and the hours of use per arm. In
# stroke these ARE the performance side of the capacity-performance gap; they map
# to ICF d445 (hand and arm use), the substrate of the d5 self-care activities.
#
# References: Uswatte G et al. (2005) Stroke 36:2493-2496 (use ratio);
# Bailey RR et al. (2014) Arch Phys Med Rehabil 95:2213-2219 (magnitude ratio /
# bilateral magnitude); Lang CE et al. (2017) (accelerometry in UL rehab).

# per-epoch ENMO (mg): compute from an n x 3 accel matrix, or accept a numeric
# vector as already-epoched ENMO.
.ul_epoch_enmo <- function(x, sampling_rate, epoch_sec) {
  if (is.numeric(x) && is.null(dim(x))) return(as.numeric(x))
  if (is.null(sampling_rate)) {
    stop("`sampling_rate` is required when passing raw accel matrices.",
         call. = FALSE)
  }
  computeENMO(x, sampling_rate = sampling_rate, epoch_sec = epoch_sec,
              unit = "mg")
}

#' Real-world upper-limb use from bilateral wrist accelerometry
#'
#' The field-standard free-living performance metrics for arm use -- the sensor
#' counterpart to a clinic upper-limb capacity test. From the affected (or
#' dominant) and unaffected (or non-dominant) wrist activity it computes the Use
#' Ratio, the Magnitude Ratio, the Bilateral Magnitude, the hours of use per arm
#' and a laterality index. Maps to ICF d445 (hand and arm use), the performance
#' substrate of the d5 self-care activities.
#'
#' @param affected,unaffected The two arms' data: each an n x 3 acceleration
#'   matrix (g units) or a numeric vector of per-epoch ENMO (mg).
#' @param sampling_rate Sampling rate in Hz (required for raw accel input).
#' @param epoch_sec Epoch length in seconds (default 5).
#' @param active_threshold ENMO (mg) above which an epoch counts as active
#'   (default 2).
#' @return an `upper_limb_use` list: `icf_code`, `use_ratio` (affected/unaffected
#'   active time; 1 = symmetric, <1 = affected used less), `magnitude_ratio`
#'   (median log activity ratio, capped +/-7; 0 = symmetric, negative =
#'   unaffected dominant), `bilateral_magnitude` (median combined activity, mg),
#'   `hours_affected`/`hours_unaffected`, and `laterality_index`
#'   ((aff-unaff)/(aff+unaff)).
#' @references Uswatte (2005); Bailey (2014); Lang (2017).
#' @seealso [summarizeFreeLiving()], [recognizeADL()]
#' @export
#' @examples
#' # affected arm active half as often as the unaffected arm (per-epoch ENMO, mg)
#' set.seed(1)
#' unaff <- c(rep(10, 100), rep(0.5, 100))
#' aff   <- c(rep(10, 50),  rep(0.5, 150))
#' upperLimbUse(aff, unaff)$use_ratio        # ~ 0.5
upperLimbUse <- function(affected, unaffected, sampling_rate = NULL,
                         epoch_sec = 5, active_threshold = 2) {
  ea <- .ul_epoch_enmo(affected, sampling_rate, epoch_sec)
  eu <- .ul_epoch_enmo(unaffected, sampling_rate, epoch_sec)
  n <- min(length(ea), length(eu))
  if (n < 1L) stop("no overlapping epochs.", call. = FALSE)
  ea <- ea[seq_len(n)]; eu <- eu[seq_len(n)]

  act_a <- ea > active_threshold; act_u <- eu > active_threshold
  hours_aff <- sum(act_a) * epoch_sec / 3600
  hours_unaff <- sum(act_u) * epoch_sec / 3600
  use_ratio <- if (sum(act_u) > 0) sum(act_a) / sum(act_u) else NA_real_
  either <- act_a | act_u
  mag_ratio <- if (any(either)) {
    stats::median(pmax(pmin(log((ea[either] + 1e-3) / (eu[either] + 1e-3)),
                            7), -7))
  } else NA_real_
  bilat_mag <- if (any(either)) stats::median((ea + eu)[either]) else NA_real_
  tot <- hours_aff + hours_unaff
  lat <- if (tot > 0) (hours_aff - hours_unaff) / tot else NA_real_

  structure(list(
    icf_code = "d445", use_ratio = use_ratio, magnitude_ratio = mag_ratio,
    bilateral_magnitude = bilat_mag, hours_affected = hours_aff,
    hours_unaffected = hours_unaff, laterality_index = lat,
    epoch_sec = epoch_sec, active_threshold = active_threshold),
    class = "upper_limb_use")
}

#' @export
print.upper_limb_use <- function(x, ...) {
  cat(sprintf("<upper_limb_use> (ICF %s)\n", x$icf_code))
  cat(sprintf("  use ratio %.2f | magnitude ratio %.2f | bilateral mag %.1f mg\n",
              x$use_ratio, x$magnitude_ratio, x$bilateral_magnitude))
  cat(sprintf("  hours: affected %.1f / unaffected %.1f | laterality %+.2f\n",
              x$hours_affected, x$hours_unaffected, x$laterality_index))
  invisible(x)
}
