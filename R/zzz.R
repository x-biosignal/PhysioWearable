.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "PhysioWearable v", utils::packageVersion(pkgname),
    " - free-living wearable accelerometry"
  )
}
