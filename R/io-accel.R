# Raw tri-axial accelerometer ingest into PhysioExperiment objects.

#' Wrap tri-axial acceleration in a PhysioExperiment
#'
#' Builds a `PhysioExperiment` (from PhysioCore) with a single 3-channel
#' `acceleration` assay (time x c(x, y, z)) at the given sampling rate.
#'
#' @param accel An n x 3 matrix of acceleration (columns x, y, z), in g units.
#' @param sampling_rate Sampling rate in Hz.
#' @param unit Acceleration unit recorded in the channel metadata (default
#'   `"g"`).
#' @param metadata Optional named list stored in the object metadata.
#'
#' @return A `PhysioExperiment` object.
#' @seealso [readAccelCSV()], [computeENMO()]
#' @export
accelToPhysioExperiment <- function(accel, sampling_rate, unit = "g",
                                    metadata = list()) {
  m <- .accel_matrix(accel)
  if (!is.numeric(sampling_rate) || length(sampling_rate) != 1L ||
      !is.finite(sampling_rate) || sampling_rate <= 0) {
    stop("`sampling_rate` must be a single positive number.", call. = FALSE)
  }
  if (!requireNamespace("PhysioCore", quietly = TRUE) ||
      !requireNamespace("S4Vectors", quietly = TRUE)) {
    stop("accelToPhysioExperiment() requires the PhysioCore and S4Vectors ",
         "packages.", call. = FALSE)
  }
  colnames(m) <- c("x", "y", "z")

  PhysioCore::PhysioExperiment(
    assays = S4Vectors::SimpleList(acceleration = m),
    colData = S4Vectors::DataFrame(label = c("x", "y", "z"),
                                   type = "accel", unit = unit),
    samplingRate = sampling_rate,
    metadata = metadata
  )
}

#' Read a raw accelerometer CSV export into a PhysioExperiment
#'
#' Reads a tri-axial accelerometer CSV (GENEActiv / ActiGraph / Axivity exports
#' and similar) and wraps it in a `PhysioExperiment`. The x/y/z columns are
#' resolved by name (case-insensitive `x`/`y`/`z`, optionally with an `accel_`
#' prefix) or by the `columns` argument.
#'
#' @param path Path to the CSV file.
#' @param sampling_rate Sampling rate in Hz.
#' @param columns Optional length-3 character (column names) or integer (column
#'   indices) selecting the x, y, z columns; `NULL` auto-detects.
#' @param skip Number of header lines to skip before the column header
#'   (default 0).
#' @param unit Acceleration unit (default `"g"`).
#' @param ... Further arguments passed to [utils::read.csv()].
#'
#' @return A `PhysioExperiment` object.
#' @seealso [accelToPhysioExperiment()]
#' @export
readAccelCSV <- function(path, sampling_rate, columns = NULL, skip = 0,
                         unit = "g", ...) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("`path` must point to an existing CSV file.", call. = FALSE)
  }
  df <- utils::read.csv(path, skip = skip, stringsAsFactors = FALSE, ...)

  if (is.null(columns)) {
    lc <- tolower(names(df))
    find <- function(ax) {
      hit <- which(lc == ax | lc == paste0("accel_", ax) |
                     lc == paste0("acc_", ax) | lc == paste0(ax, "_g"))
      if (length(hit) == 0L) NA_integer_ else hit[1]
    }
    columns <- c(find("x"), find("y"), find("z"))
    if (any(is.na(columns))) {
      stop("could not auto-detect x/y/z columns; pass `columns` explicitly.",
           call. = FALSE)
    }
  } else if (is.character(columns)) {
    columns <- match(columns, names(df))
    if (any(is.na(columns))) {
      stop("named `columns` not found in the CSV header.", call. = FALSE)
    }
  }
  if (length(columns) != 3L) {
    stop("`columns` must select exactly three columns (x, y, z).",
         call. = FALSE)
  }

  m <- as.matrix(df[, columns, drop = FALSE])
  storage.mode(m) <- "double"
  accelToPhysioExperiment(m, sampling_rate, unit = unit)
}
