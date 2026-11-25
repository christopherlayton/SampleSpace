pv <- get_object("p_values")
ok <- is.matrix(pv) && identical(dim(pv), c(10L, 1000L)) && all(pv >= 0 & pv <= 1)
expect_true(ok, label = "`p_values` holds 10 p-values for each of 1,000 studies",
            message = "`p_values <- replicate(1000, one_study())` gives a 10 × 1000 matrix.")
if (ok) {
  expect_true(abs(mean(pv < 0.05) - 0.05) < 0.01, label = "the single tests are false alarms about 5% of the time",
              message = "Keep `one_study()` as it is: both groups come from the same population.")
  hit <- apply(pv < 0.05, 2, any)
  expect_object("any_hit", hit, message = "`apply(p_values < 0.05, 2, any)`: for each column (study), is any p below .05?")
  expect_object("rate", mean(hit), message = "`mean(any_hit)`: the share of studies reporting a \"finding\".")
  expect_object("bonf_rate", mean(apply(pv < 0.005, 2, any)),
                message = "The same, comparing each p with `0.05 / 10`: `mean(apply(p_values < 0.05 / 10, 2, any))`.")
}
expect_object("theory", 1 - 0.95^10, message = "`1 - 0.95^10`.")
rep0 <- c(0.004, 0.011, 0.020, 0.031, 0.240)
expect_object("holm", p.adjust(rep0, method = "holm"), message = "`p.adjust(reported, method = \"holm\")`.")
expect_object("bonf", p.adjust(rep0, method = "bonferroni"), message = "`p.adjust(reported, method = \"bonferroni\")`.")
