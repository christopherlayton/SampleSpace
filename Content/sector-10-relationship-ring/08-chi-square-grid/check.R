c0 <- matrix(c(28, 22, 20, 30), nrow = 2, byrow = TRUE)
p0 <- chisq.test(c0, correct = FALSE)
pr <- get_object("pearson")
expect_true(inherits(pr, "htest") && isTRUE(all.equal(unname(pr$statistic), unname(p0$statistic))),
            label = "`pearson` is Pearson's χ² without the correction",
            message = "`chisq.test(counts, correct = FALSE)`: without `correct = FALSE`, a 2 × 2 table gets Yates' correction.")
expect_object("expected", p0$expected, tolerance = 1e-10, check_attributes = FALSE, message = "`pearson$expected`.")
expect_object("resid", unname(p0$residuals), tolerance = 1e-10, check_attributes = FALSE, message = "`pearson$residuals`.")
expect_object("v", sqrt(unname(p0$statistic) / 100), tolerance = 1e-10, check_attributes = FALSE,
              message = "V = √(χ² ÷ (N × (k − 1))): `sqrt(unname(pearson$statistic) / (sum(counts) * (min(dim(counts)) - 1)))`.")
y0 <- chisq.test(c0)
y <- get_object("yates")
expect_true(inherits(y, "htest") && isTRUE(all.equal(unname(y$statistic), unname(y0$statistic))),
            label = "`yates` is R's default, with Yates' correction", message = "`chisq.test(counts)`.")
f <- get_object("fisher")
expect_true(inherits(f, "htest") && grepl("Fisher", f$method) && isTRUE(all.equal(f$p.value, fisher.test(c0)$p.value)),
            label = "`fisher` is Fisher's exact test", message = "`fisher.test(counts)`.")
