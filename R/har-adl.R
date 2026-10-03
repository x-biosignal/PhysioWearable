# Human Activity Recognition (HAR) for ADL: recognise which everyday activity a
# person is doing from wearable accelerometer features, and map it to the ICF
# Activities & Participation domains.
#
# summarizeFreeLiving() answers "how much / how intense" (the intensity time-use
# performance qualifier). This module answers "doing WHAT" -- it windows the raw
# signal, extracts a compact time-and-frequency feature set per window (the
# UCI-HAR feature family), classifies each window into an activity and turns the
# recognised activities into an ADL time budget linked to ICF d-codes. The
# classifier is a dependency-free k-nearest-neighbours on standardised features;
# it is model-agnostic, so a stronger engine (PhysioML ROCKET / a torch model)
# can be substituted by supplying its own predict step.
#
# References: Anguita D et al. (2013) UCI HAR dataset; Bao & Intille (2004).

# --- windowing -------------------------------------------------------------

# start indices of fixed windows with the given overlap fraction.
.har_window_starts <- function(n, win_n, overlap) {
  step <- max(1L, as.integer(round(win_n * (1 - overlap))))
  starts <- seq.int(1L, n - win_n + 1L, by = step)
  if (!length(starts)) integer(0) else starts
}

# --- spectral helpers (base R fft) -----------------------------------------

.har_spectrum <- function(v, sampling_rate) {
  v <- v - mean(v)
  n <- length(v)
  p <- (Mod(stats::fft(v))^2)[seq_len(n %/% 2) + 1L]      # drop DC, first half
  if (!length(p) || sum(p) == 0) {
    return(list(dom_freq = 0, energy = 0, entropy = 0))
  }
  freqs <- (seq_along(p)) * sampling_rate / n
  ps <- p / sum(p)
  list(dom_freq = freqs[which.max(p)],
       energy = sum(p) / n,
       entropy = -sum(ps * log(ps + 1e-12)))
}

# features of one window (n x 3 accel matrix, g units).
.har_window_features <- function(w, sampling_rate) {
  x <- w[, 1]; y <- w[, 2]; z <- w[, 3]
  vm <- sqrt(x^2 + y^2 + z^2)
  ax <- list(x = x, y = y, z = z, vm = vm)
  stat <- unlist(lapply(names(ax), function(nm) {
    a <- ax[[nm]]
    stats::setNames(
      c(mean(a), stats::sd(a), stats::mad(a), mean(a^2),
        stats::IQR(a), min(a), max(a)),
      paste0(nm, c("_mean", "_sd", "_mad", "_energy", "_iqr", "_min", "_max")))
  }))
  cor_safe <- function(a, b) {
    if (stats::sd(a) < 1e-9 || stats::sd(b) < 1e-9) 0 else stats::cor(a, b)
  }
  sp <- .har_spectrum(vm, sampling_rate)
  jerk <- diff(vm) * sampling_rate
  c(stat,
    sma = mean(abs(x) + abs(y) + abs(z)),
    cor_xy = cor_safe(x, y), cor_xz = cor_safe(x, z), cor_yz = cor_safe(y, z),
    dom_freq = sp$dom_freq, spec_energy = sp$energy, spec_entropy = sp$entropy,
    jerk_rms = if (length(jerk)) sqrt(mean(jerk^2)) else 0)
}

#' Windowed accelerometer features for activity recognition
#'
#' Splits a raw tri-axial signal into fixed overlapping windows and computes, per
#' window, the compact time- and frequency-domain feature set used for human
#' activity recognition (per-axis and vector-magnitude mean/sd/MAD/energy/IQR/
#' range, the signal-magnitude area, inter-axis correlations, the dominant
#' frequency, spectral energy and entropy, and jerk RMS). Dependency-free.
#'
#' @param accel An n x 3 acceleration matrix (g units; columns x, y, z).
#' @param sampling_rate Sampling rate in Hz.
#' @param window_sec Window length in seconds (default 2.56, the UCI-HAR value).
#' @param overlap Window overlap fraction in `[0, 1)` (default 0.5).
#' @return A data.frame with `window`, `start_sec`, `end_sec` and one column per
#'   feature (one row per window).
#' @references Anguita D, et al. (2013). ESANN.
#' @seealso [trainADL()], [recognizeADL()]
#' @export
#' @examples
#' fs <- 20; t <- seq(0, 20, 1 / fs)
#' walk <- cbind(0.1 * sin(2 * pi * 1.8 * t), 0.1 * cos(2 * pi * 1.8 * t), 1)
#' head(adlFeatures(walk, fs), 3)
adlFeatures <- function(accel, sampling_rate, window_sec = 2.56, overlap = 0.5) {
  m <- .accel_matrix(accel)
  if (!is.numeric(sampling_rate) || length(sampling_rate) != 1L ||
      sampling_rate <= 0) {
    stop("`sampling_rate` must be a single positive number.", call. = FALSE)
  }
  if (!is.numeric(overlap) || overlap < 0 || overlap >= 1) {
    stop("`overlap` must be in [0, 1).", call. = FALSE)
  }
  win_n <- max(2L, as.integer(round(window_sec * sampling_rate)))
  if (win_n > nrow(m)) {
    stop(sprintf("window (%g s) is longer than the signal.", window_sec),
         call. = FALSE)
  }
  starts <- .har_window_starts(nrow(m), win_n, overlap)
  feats <- lapply(starts, function(s)
    .har_window_features(m[s:(s + win_n - 1L), , drop = FALSE], sampling_rate))
  fm <- as.data.frame(do.call(rbind, feats))
  data.frame(window = seq_along(starts),
             start_sec = (starts - 1) / sampling_rate,
             end_sec = (starts - 1 + win_n) / sampling_rate,
             fm, row.names = NULL, check.names = FALSE)
}

# feature columns = everything except the window/time bookkeeping.
.har_feature_cols <- function(features) {
  setdiff(names(features), c("window", "start_sec", "end_sec"))
}

# --- classifier (dependency-free kNN on standardised features) --------------

.har_X <- function(features, cols = NULL) {
  if (is.data.frame(features)) {
    cols <- cols %||% .har_feature_cols(features)
    as.matrix(features[, cols, drop = FALSE])
  } else {
    X <- as.matrix(features); X
  }
}

.knn_predict <- function(Xtr, ytr, Xte, k) {
  ytr <- as.factor(ytr)
  out <- vapply(seq_len(nrow(Xte)), function(i) {
    d <- sqrt(colSums((t(Xtr) - Xte[i, ])^2))
    nn <- order(d)[seq_len(min(k, length(d)))]
    tb <- sort(table(ytr[nn]), decreasing = TRUE)
    names(tb)[1]
  }, character(1))
  factor(out, levels = levels(ytr))
}

#' Train an ADL activity recogniser from labelled windows
#'
#' Learns a k-nearest-neighbours classifier over standardised [adlFeatures()],
#' mapping a window's features to an activity label. Dependency-free and
#' model-agnostic: for a stronger engine, extract features here and classify with
#' PhysioML (ROCKET/torch) instead -- the ICF mapping ([adlToICF()]) is unchanged.
#'
#' @param features Training features: an [adlFeatures()] data.frame or a numeric
#'   feature matrix (one row per window).
#' @param labels Activity label per window (length = number of windows).
#' @param k Neighbours for the vote (default 5).
#' @param window_sec,overlap Window settings to store so [recognizeADL()] can
#'   re-extract features consistently (defaults match [adlFeatures()]).
#' @return an `adl_model` object.
#' @seealso [recognizeADL()], [adlFeatures()], [adlToICF()]
#' @export
#' @examples
#' set.seed(1)
#' fs <- 20; t <- seq(0, 30, 1 / fs)
#' walk <- cbind(0.2 * sin(2 * pi * 1.8 * t), 0.2 * cos(2 * pi * 1.8 * t), 1)
#' sit  <- cbind(rnorm(length(t), 0, 0.01), rnorm(length(t), 0, 0.01), 1)
#' fw <- adlFeatures(walk, fs); fs2 <- adlFeatures(sit, fs)
#' feats <- rbind(fw, fs2)
#' labs <- c(rep("walking", nrow(fw)), rep("sitting", nrow(fs2)))
#' m <- trainADL(feats, labs)
#' m
trainADL <- function(features, labels, k = 5, window_sec = 2.56,
                     overlap = 0.5) {
  cols <- if (is.data.frame(features)) .har_feature_cols(features)
          else colnames(features)
  X <- .har_X(features, cols)
  if (nrow(X) != length(labels)) {
    stop("`labels` must have one entry per window (row of `features`).",
         call. = FALSE)
  }
  center <- colMeans(X)
  scale <- apply(X, 2, stats::sd); scale[scale < 1e-9] <- 1
  Xs <- sweep(sweep(X, 2, center, "-"), 2, scale, "/")
  structure(list(Xtr = Xs, ytr = as.factor(labels), k = as.integer(k),
                 center = center, scale = scale, feature_names = cols,
                 window_sec = window_sec, overlap = overlap),
            class = "adl_model")
}

#' @export
#' @param object an `adl_model`.
#' @param newdata features to classify ([adlFeatures()] data.frame or matrix).
#' @param ... unused.
#' @rdname trainADL
predict.adl_model <- function(object, newdata, ...) {
  avail <- if (is.data.frame(newdata)) names(newdata) else colnames(newdata)
  miss <- setdiff(object$feature_names, avail)
  if (length(miss)) {
    stop("newdata is missing feature(s): ", paste(miss, collapse = ", "),
         call. = FALSE)
  }
  X <- .har_X(newdata, object$feature_names)
  X <- X[, object$feature_names, drop = FALSE]
  Xs <- sweep(sweep(X, 2, object$center, "-"), 2, object$scale, "/")
  .knn_predict(object$Xtr, object$ytr, Xs, object$k)
}

#' @export
print.adl_model <- function(x, ...) {
  cat(sprintf("<adl_model> kNN(k=%d) | %d training windows | %d features\n",
              x$k, nrow(x$Xtr), length(x$feature_names)))
  cat(sprintf("  activities: %s\n", paste(levels(x$ytr), collapse = ", ")))
  invisible(x)
}

#' Recognise ADL activities in a raw recording
#'
#' Windows a raw tri-axial signal, extracts [adlFeatures()] and classifies each
#' window with a trained [trainADL()] model, giving the activity per window.
#'
#' @param model an `adl_model`.
#' @param accel an n x 3 acceleration matrix (g units).
#' @param sampling_rate sampling rate in Hz.
#' @param window_sec,overlap window settings (default: the model's).
#' @return a data.frame with `window`, `start_sec`, `end_sec` and `activity`.
#' @seealso [adlBudget()], [adlToICF()]
#' @importFrom stats predict
#' @export
recognizeADL <- function(model, accel, sampling_rate,
                         window_sec = model$window_sec,
                         overlap = model$overlap) {
  stopifnot(inherits(model, "adl_model"))
  feats <- adlFeatures(accel, sampling_rate, window_sec = window_sec,
                       overlap = overlap)
  feats$activity <- predict(model, feats)
  feats[, c("window", "start_sec", "end_sec", "activity")]
}

#' Time budget of recognised activities
#'
#' @param recognized a [recognizeADL()] result (or a data.frame with an
#'   `activity` column and `start_sec`).
#' @return a data.frame `activity`, `n_windows`, `minutes`, `proportion`,
#'   ordered by time.
#' @seealso [adlToICF()]
#' @export
adlBudget <- function(recognized) {
  if (!"activity" %in% names(recognized)) {
    stop("`recognized` needs an 'activity' column.", call. = FALSE)
  }
  step <- if ("start_sec" %in% names(recognized) && nrow(recognized) > 1)
    stats::median(diff(recognized$start_sec)) else NA_real_
  tb <- table(recognized$activity)
  n <- as.integer(tb)
  minutes <- if (is.finite(step)) n * step / 60 else NA_real_
  out <- data.frame(activity = names(tb), n_windows = n, minutes = minutes,
                    proportion = n / sum(n), stringsAsFactors = FALSE)
  out[order(-out$n_windows), ]
}

# --- activity -> ICF Activities & Participation -----------------------------

.adl_icf_map <- function() {
  rbind(
    c("walking", "d450", "Walking"),
    c("walking_upstairs", "d455", "Moving around"),
    c("walking_downstairs", "d455", "Moving around"),
    c("stairs", "d455", "Moving around"),
    c("running", "d455", "Moving around"),
    c("cycling", "d455", "Moving around"),
    c("sitting", "d415", "Maintaining a body position"),
    c("standing", "d415", "Maintaining a body position"),
    c("lying", "d415", "Maintaining a body position"),
    c("laying", "d415", "Maintaining a body position"),
    c("sit_to_stand", "d410", "Changing basic body position"),
    c("transition", "d410", "Changing basic body position"),
    c("housework", "d640", "Doing housework"),
    c("cleaning", "d640", "Doing housework"),
    c("vacuuming", "d640", "Doing housework"),
    c("ironing", "d640", "Doing housework"),
    c("eating", "d550", "Eating"),
    c("drinking", "d560", "Drinking"),
    c("dressing", "d540", "Dressing"),
    c("washing", "d510", "Washing oneself"),
    c("toileting", "d530", "Toileting"),
    c("grooming", "d520", "Caring for body parts"),
    c("cooking", "d630", "Preparing meals"),
    c("food_preparation", "d630", "Preparing meals"))
}

#' Map recognised ADL activities to ICF Activities & Participation codes
#'
#' Turns recognised activities into their ICF d-codes, stamped with the
#' `performance` qualifier (real-world doing), and attaches the time budget when
#' available. Activities are matched case-insensitively; unmapped labels are
#' dropped with a warning. The result feeds the cross-modal ICF construct in
#' PhysioRehab.
#'
#' @param x a [recognizeADL()] result, an [adlBudget()] result, or a character
#'   vector of activity labels.
#' @return a data.frame `activity`, `icf_code`, `icf_title`, `qualifier`
#'   (`"performance"`) and, when a budget is available, `minutes` and
#'   `proportion` aggregated per ICF code.
#' @seealso [recognizeADL()], [adlBudget()], [freeLivingICF()]
#' @export
#' @examples
#' adlToICF(c("walking", "sitting", "walking", "eating"))
adlToICF <- function(x) {
  map <- as.data.frame(.adl_icf_map(), stringsAsFactors = FALSE)
  names(map) <- c("activity", "icf_code", "icf_title")

  budget <- NULL
  if (is.data.frame(x) && "activity" %in% names(x)) {
    acts <- x$activity
    if (all(c("minutes", "proportion") %in% names(x))) budget <- x
    else budget <- adlBudget(x)
  } else if (is.character(x) || is.factor(x)) {
    acts <- as.character(x)
    budget <- data.frame(activity = names(table(acts)),
                         minutes = NA_real_,
                         proportion = as.numeric(table(acts)) / length(acts),
                         stringsAsFactors = FALSE)
  } else {
    stop("`x` must be a recognizeADL/adlBudget data.frame or a label vector.",
         call. = FALSE)
  }

  key <- tolower(as.character(budget$activity))
  hit <- match(key, map$activity)
  unmapped <- budget$activity[is.na(hit)]
  if (length(unmapped)) {
    warning("no ICF map for activity: ", paste(unique(unmapped), collapse = ", "),
            call. = FALSE)
  }
  b <- budget[!is.na(hit), , drop = FALSE]
  m <- map[hit[!is.na(hit)], , drop = FALSE]
  agg <- stats::aggregate(
    cbind(minutes = b$minutes, proportion = b$proportion),
    by = list(icf_code = m$icf_code, icf_title = m$icf_title), sum, na.rm = FALSE)
  agg$qualifier <- "performance"
  agg[order(-agg$proportion),
      c("icf_code", "icf_title", "qualifier", "minutes", "proportion")]
}
