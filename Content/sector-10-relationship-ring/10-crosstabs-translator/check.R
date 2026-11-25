s0 <- haven::read_sav("teaching_study.sav")
m0 <- haven::as_factor(s0$method)
pa0 <- factor(as.numeric(s0$score) >= 70, levels = c(FALSE, TRUE), labels = c("Did not pass", "Passed"))
t0 <- table(m0, pa0)
expect_true(is.factor(teach$passed) && identical(levels(teach$passed), c("Did not pass", "Passed")) &&
              identical(as.character(teach$passed), as.character(pa0)),
            label = "`passed` is a factor: Did not pass, Passed",
            message = "`factor(teach$score >= 70, levels = c(FALSE, TRUE), labels = c(\"Did not pass\", \"Passed\"))`.")
tb <- get_object("tab")
expect_true(inherits(tb, "table") && identical(as.vector(tb), as.vector(t0)),
            label = "`tab` is the Crosstabulation (11, 4 / 4, 11)", message = "`table(teach$method, teach$passed)`.")
x0 <- chisq.test(t0, correct = FALSE)
y0 <- chisq.test(t0)
pr <- get_object("pearson"); yt <- get_object("yates"); fi <- get_object("fisher")
expect_true(inherits(pr, "htest") && isTRUE(all.equal(unname(pr$statistic), unname(x0$statistic))),
            label = "`pearson` is the Pearson Chi-Square row (6.533)", message = "`chisq.test(tab, correct = FALSE)`.")
expect_true(inherits(yt, "htest") && isTRUE(all.equal(unname(yt$statistic), unname(y0$statistic))),
            label = "`yates` is the Continuity Correction row (4.800)", message = "`chisq.test(tab)`: Yates is R's 2 × 2 default.")
expect_true(inherits(fi, "htest") && isTRUE(all.equal(fi$p.value, fisher.test(t0)$p.value)),
            label = "`fisher` is Fisher's Exact Test (.027)", message = "`fisher.test(tab)`.")
expect_object("g2", 2 * sum(t0 * log(t0 / x0$expected)), tolerance = 1e-10, check_attributes = FALSE,
              message = "G² = 2 Σ O ln(O ÷ E): `2 * sum(tab * log(tab / pearson$expected))`.")
ph <- get_object("phi_value"); vv <- get_object("v")
want <- sqrt(unname(x0$statistic) / 30)
expect_true(inherits(ph, "effectsize_table") && isTRUE(all.equal(abs(ph[[1]][1]), want)),
            label = "`phi_value` is φ (.467)", message = "`phi(tab, adjust = FALSE)`.")
expect_true(inherits(vv, "effectsize_table") && isTRUE(all.equal(vv$Cramers_v, want)),
            label = "`v` is Cramér's V (.467)", message = "`cramers_v(tab, adjust = FALSE)`.")
