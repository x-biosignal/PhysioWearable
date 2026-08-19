# Points approximately uniformly on the unit sphere (Fibonacci lattice).
.sphere_points <- function(n = 40) {
  gr <- (1 + sqrt(5)) / 2
  i <- 0:(n - 1)
  th <- acos(1 - 2 * (i + 0.5) / n)
  ph <- 2 * pi * i / gr
  cbind(sin(th) * cos(ph), sin(th) * sin(ph), cos(th))
}

# A still recording: each sphere orientation held for one window, mis-calibrated
# by scale_true / offset_true (device measures s/scale + offset).
.miscalibrated_still <- function(fs = 30, window_sec = 10, n_or = 40,
                                 scale_true = c(0.90, 1.05, 1.10),
                                 offset_true = c(0.03, -0.04, 0.02),
                                 noise = 0.003, seed = 1) {
  set.seed(seed)
  S <- .sphere_points(n_or)
  M <- sweep(sweep(S, 2, scale_true, "/"), 2, offset_true, "+")
  win <- round(window_sec * fs)
  raw <- do.call(rbind, lapply(seq_len(n_or), function(k) {
    matrix(rep(M[k, ], each = win), win, 3) + matrix(stats::rnorm(win * 3, 0,
                                                                  noise), win, 3)
  }))
  list(raw = raw, sphere = S, M = M, scale_true = scale_true,
       offset_true = offset_true)
}
