expect_object("mean_hours", 1050.883984338293, message="`hours.mean()`.")
expect_object("median_hours", 261.0, message="`hours.median()`.")
expect_object("sd_hours", 1714.7919585168268,
              message="The sample SD divides by n − 1: `hours.std()` (or `np.std(hours, ddof=1)`).")
expect_object("sd_numpy", 1714.1204127857607,
              message="numpy's default: `np.std(hours)`. It should be a little *smaller* than `sd_hours`.")
expect_object("skew_hours", 2.092163944630586, message="`hours.skew()`.")
expect_object("kurt_hours", 4.315786774426426, message="`hours.kurt()` gives excess kurtosis (0 for a normal curve).")
expect_object("iqr_hours", 191.97, message="Q3 − Q1: `hours.quantile(0.75) - hours.quantile(0.25)`.")
expect_called("describe")
