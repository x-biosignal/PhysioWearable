## VAL-10: PhysioWearable ENMO parity fixture against GGIR (van Hees / GGIR gold standard)
##
## Provenance: real Axivity AX3 device recording shipped with GGIRread
## (system.file("testfiles/ax3_testfile.cwa", package = "GGIRread")), 100 Hz,
## ~176 s. We store GGIR's ENMO metric (GGIR::g.applymetrics, 5 s epochs) as the
## external reference. Only the derived ENMO values are bundled (not the GGIRread
## file), so PhysioWearable stays MIT while GGIRread/GGIR remain Suggests used at
## test time to re-read the file and (optionally) recompute the reference.
##
## Regenerate:
##   Rscript physio-ecosystem/PhysioWearable/data-raw/wearable_ggir_reference.R
## Requires: GGIR, GGIRread.

suppressPackageStartupMessages({ library(GGIR); library(GGIRread) })

f  <- system.file("testfiles/ax3_testfile.cwa", package = "GGIRread")
d  <- readAxivity(f, start = 0, end = Inf, progressBar = FALSE)
sr <- d$header$frequency
xyz <- as.matrix(d$data[, c("x", "y", "z")])

epoch_sec <- 5
allfields <- c("do.bfen","do.enmo","do.lfenmo","do.en","do.hfen","do.hfenplus",
  "do.mad","do.anglex","do.angley","do.anglez","do.roll_med_acc_x",
  "do.roll_med_acc_y","do.roll_med_acc_z","do.dev_roll_med_acc_x",
  "do.dev_roll_med_acc_y","do.dev_roll_med_acc_z","do.enmoa","do.lfen","do.hfx",
  "do.hfy","do.hfz","do.lfx","do.lfy","do.lfz","do.bfx","do.bfy","do.bfz",
  "do.zcx","do.zcy","do.zcz","do.brondcounts","do.neishabouricounts")
m2 <- as.data.frame(as.list(setNames(rep(FALSE, length(allfields)), allfields)))
m2$do.enmo <- TRUE
gg <- GGIR::g.applymetrics(data = xyz, sf = sr, ws3 = epoch_sec, metrics2do = m2)

ref <- list(
  enmo_ggir_mg = as.numeric(gg$ENMO) * 1000,   # GGIR ENMO per 5 s epoch, mg
  epoch_sec    = epoch_sec,
  sampling_rate = sr,
  n_samples    = nrow(xyz),
  source       = "GGIRread::ax3_testfile.cwa (real Axivity AX3, 100 Hz)",
  reference_tool = paste0("GGIR ", utils::packageVersion("GGIR"),
                          " g.applymetrics; GGIRread ", utils::packageVersion("GGIRread")),
  metric       = "ENMO = max(sqrt(x^2+y^2+z^2) - 1, 0), mg, 5 s epoch means"
)

out <- file.path("physio-ecosystem", "PhysioWearable", "tests", "testthat",
                 "fixtures", "wearable-ggir-reference.rds")
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
saveRDS(ref, out, version = 2)
cat("wrote", out, "-", length(ref$enmo_ggir_mg), "epochs; mean ENMO",
    round(mean(ref$enmo_ggir_mg), 2), "mg\n")
