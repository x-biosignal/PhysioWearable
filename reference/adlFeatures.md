# Windowed accelerometer features for activity recognition

Splits a raw tri-axial signal into fixed overlapping windows and
computes, per window, the compact time- and frequency-domain feature set
used for human activity recognition (per-axis and vector-magnitude
mean/sd/MAD/energy/IQR/ range, the signal-magnitude area, inter-axis
correlations, the dominant frequency, spectral energy and entropy, and
jerk RMS). Dependency-free.

## Usage

``` r
adlFeatures(accel, sampling_rate, window_sec = 2.56, overlap = 0.5)
```

## Arguments

- accel:

  An n x 3 acceleration matrix (g units; columns x, y, z).

- sampling_rate:

  Sampling rate in Hz.

- window_sec:

  Window length in seconds (default 2.56, the UCI-HAR value).

- overlap:

  Window overlap fraction in `[0, 1)` (default 0.5).

## Value

A data.frame with `window`, `start_sec`, `end_sec` and one column per
feature (one row per window).

## References

Anguita D, et al. (2013). ESANN.

## See also

[`trainADL()`](https://x-biosignal.github.io/PhysioWearable/reference/trainADL.md),
[`recognizeADL()`](https://x-biosignal.github.io/PhysioWearable/reference/recognizeADL.md)

## Examples

``` r
fs <- 20; t <- seq(0, 20, 1 / fs)
walk <- cbind(0.1 * sin(2 * pi * 1.8 * t), 0.1 * cos(2 * pi * 1.8 * t), 1)
head(adlFeatures(walk, fs), 3)
#>   window start_sec end_sec       x_mean       x_sd      x_mad    x_energy
#> 1      1       0.0    2.55  0.006749064 0.07038138 0.10149095 0.004901961
#> 2      2       1.3    3.85 -0.003616329 0.07161870 0.10492697 0.005041743
#> 3      3       2.6    5.15 -0.002873612 0.07180055 0.09876757 0.005062493
#>       x_iqr       x_min      x_max        y_mean       y_sd     y_mad
#> 1 0.1427189 -0.09822873 0.10000000 -1.155605e-17 0.07211103 0.1080769
#> 2 0.1410726 -0.10000000 0.09980267 -5.698423e-03 0.07088230 0.1014910
#> 3 0.1450751 -0.10000000 0.09822873  6.106736e-03 0.07069809 0.1013630
#>      y_energy     y_iqr       y_min      y_max z_mean z_sd z_mad z_energy z_iqr
#> 1 0.005098039 0.1413516 -0.10000000 0.10000000      1    0     0        1     0
#> 2 0.004958257 0.1427189 -0.10000000 0.09822873      1    0     0        1     0
#> 3 0.004937507 0.1362346 -0.09980267 0.10000000      1    0     0        1     0
#>   z_min z_max  vm_mean vm_sd vm_mad vm_energy vm_iqr   vm_min   vm_max      sma
#> 1     1     1 1.004988     0      0      1.01      0 1.004988 1.004988 1.126747
#> 2     1     1 1.004988     0      0      1.01      0 1.004988 1.004988 1.127493
#> 3     1     1 1.004988     0      0      1.01      0 1.004988 1.004988 1.127395
#>          cor_xy cor_xz cor_yz dom_freq spec_energy spec_entropy jerk_rms
#> 1  4.873535e-17      0      0        0           0            0        0
#> 2 -2.196440e-02      0      0        0           0            0        0
#> 3  1.870521e-02      0      0        0           0            0        0
```
