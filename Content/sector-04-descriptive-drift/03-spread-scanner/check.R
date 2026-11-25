truth <- utils::read.csv("astronauts.csv")
h <- truth$hours_mission
expect_object("sd_hours", sd(h))
expect_object("var_hours", var(h), message = "Variance is `var()`, the SD squared.")
expect_object("iqr_hours", IQR(h))
expect_object("p90_hours", as.numeric(quantile(h, 0.9)),
              message = "Use `quantile(hours, 0.9)` (0.9, not 90), wrapped in `as.numeric()`.")
expect_object("range_hours", range(h),
              message = "`range(hours)` returns two numbers: the minimum and the maximum.")
