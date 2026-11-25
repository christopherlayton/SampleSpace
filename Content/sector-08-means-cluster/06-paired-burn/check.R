s <- utils::read.csv("wellbeing_survey.csv")
d <- s$anxiety_pre - s$anxiety_post
want <- t.test(s$anxiety_pre, s$anxiety_post, paired = TRUE)
p <- get_object("paired")
expect_true(inherits(p, "htest") && isTRUE(all.equal(unname(p$statistic), unname(want$statistic))) &&
              unname(p$parameter) == 36,
            label = "`paired` is the paired t-test (t(36) = 4.94)",
            message = paste("`t.test(survey$anxiety_pre, survey$anxiety_post, paired = TRUE)`. Without `paired = TRUE`",
                            "R runs Welch's two-group test, which ignores that these are the same people."))
dd <- get_object("diffs")
expect_true(is.numeric(dd) && length(dd) == length(d) && isTRUE(all.equal(dd, d)),
            label = "`diffs` is pre − post for every student",
            message = "`survey$anxiety_pre - survey$anxiety_post` (40 values, 3 of them NA).")
o <- get_object("on_diffs")
expect_true(inherits(o, "htest") && isTRUE(all.equal(unname(o$statistic), unname(want$statistic))),
            label = "`on_diffs` gives the same t as the paired test",
            message = "`t.test(diffs)`: a one-sample test of the differences against 0.")
expect_object("n_pairs", sum(!is.na(d)), message = "Count the differences that aren't NA: `sum(!is.na(diffs))`.")
expect_object("mean_diff", mean(d, na.rm = TRUE), message = "`mean(diffs, na.rm = TRUE)`.")
expect_object("d_z", mean(d, na.rm = TRUE) / sd(d, na.rm = TRUE),
              message = "d_z is the mean difference over the SD of the differences: `mean_diff / sd(diffs, na.rm = TRUE)`.")
