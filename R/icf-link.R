# Link free-living physical-behaviour metrics to the ICF Activities &
# Participation codes, stamped with the *performance* qualifier.
#
# The ICF distinguishes CAPACITY (what a person can do in a standardised, often
# clinical, setting) from PERFORMANCE (what they actually do in their real
# environment). Free-living accelerometry is a direct window on performance --
# the d5/d6 activities of daily living as they are lived -- which is exactly the
# gap a clinic test cannot see. This bridge maps the summary metrics to their
# ICF codes so free-living output speaks the same language as the clinical
# instruments (PhysioClinical) and the rehab reasoning layer (PhysioRehab).

# Built-in metric -> ICF map, mirroring the free-living rows registered in
# PhysioAnnotationHub's metric_icf_map.csv. Kept here so the bridge works with
# no hard dependency; the hub is consulted first when available.
.free_icf_map <- function() {
  data.frame(
    metric = c("steps_per_day", "mvpa_min", "sedentary_min",
               "physical_activity_volume", "walking_bouts"),
    agg_field = c("steps", "mvpa_min", "sedentary_min", "mean_enmo_mg", NA),
    icf_code = c("d450", "d570", "d570", "d570", "d455"),
    icf_title = c("Walking", "Looking after one's health",
                  "Looking after one's health", "Looking after one's health",
                  "Moving around"),
    stringsAsFactors = FALSE
  )
}

#' Map free-living metrics to ICF codes (performance qualifier)
#'
#' Returns the ICF Activities & Participation codes for free-living
#' physical-behaviour metrics, each labelled with the ICF `performance`
#' qualifier -- the distinguishing feature of free-living monitoring, which
#' captures what a person actually does in daily life rather than the
#' `capacity` a clinic test measures. When a [summarizeFreeLiving()] result is
#' supplied, each mapped metric's aggregate value is attached.
#'
#' Uses the maintained ontology in the suggested package
#' \pkg{PhysioAnnotationHub} when available (its free-living rows), falling back
#' to a built-in table otherwise.
#'
#' @param x A `freeliving_summary` (from [summarizeFreeLiving()]) or a character
#'   vector of metric ids; `NULL` (default) returns the full free-living map.
#' @param hub Optional `PhysioAnnotationHub` object passed through to the
#'   ontology lookup.
#' @return A data frame with `metric`, `icf_code`, `icf_title`, `qualifier`
#'   (always `"performance"`) and, for a summary input, `value`.
#' @seealso [summarizeFreeLiving()]
#' @export
#' @examples
#' freeLivingICF()                       # the free-living metric -> ICF map
#' freeLivingICF(c("mvpa_min", "steps_per_day"))
freeLivingICF <- function(x = NULL, hub = NULL) {
  map <- .free_icf_map()

  # prefer the maintained ontology's code(s) where it knows the metric
  if (requireNamespace("PhysioAnnotationHub", quietly = TRUE)) {
    for (i in seq_len(nrow(map))) {
      codes <- suppressWarnings(tryCatch(
        PhysioAnnotationHub::tagICF(map$metric[i], hub = hub),
        error = function(e) character(0)))
      if (length(codes)) map$icf_code[i] <- codes[1]
    }
  }

  summary_obj <- inherits(x, "freeliving_summary")
  if (is.character(x)) {
    map <- map[map$metric %in% x, , drop = FALSE]
    if (!nrow(map)) {
      warning("no free-living ICF link for: ", paste(x, collapse = ", "),
              call. = FALSE)
    }
  }

  out <- data.frame(metric = map$metric, icf_code = map$icf_code,
                    icf_title = map$icf_title, qualifier = "performance",
                    stringsAsFactors = FALSE)
  if (summary_obj) {
    out$value <- vapply(map$agg_field, function(f)
      if (is.na(f)) NA_real_ else as.numeric(x$aggregate[[f]] %||% NA_real_),
      numeric(1))
  }
  rownames(out) <- NULL
  out
}

# minimal null-coalesce (avoid importing one just for the bridge)
`%||%` <- function(a, b) if (is.null(a)) b else a
