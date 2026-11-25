expect_object("above_130", pnorm(130, mean = 100, sd = 15, lower.tail = FALSE),
              message = paste("`pnorm()` gives the area *below* a score. For the area above 130, add",
                              "`lower.tail = FALSE` (it should be about 0.023, matching the lab)."))
expect_object("z_130", 2,
              message = "Subtract the mean, then divide by the SD: `(130 - 100) / 15`.")
expect_object("below_85", pnorm(85, mean = 100, sd = 15),
              message = paste("85 is one SD below the mean. `pnorm(85, mean = 100, sd = 15)` gives the",
                              "area below it (about 0.16)."))
expect_object("middle_95", qnorm(c(0.025, 0.975), mean = 100, sd = 15), tolerance = 1e-4,
              message = paste("`qnorm()` goes the other way: give it proportions and it returns scores.",
                              "The middle 95% leaves 2.5% in each tail: `qnorm(c(0.025, 0.975), mean = 100, sd = 15)`."))
expect_called("pnorm")
expect_called("qnorm")
