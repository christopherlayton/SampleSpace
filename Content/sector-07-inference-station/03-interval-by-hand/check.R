x <- utils::read.csv("wellbeing_survey.csv")$anxiety_pre
n <- length(x)
se <- sd(x) / sqrt(n)
tc <- qt(0.975, n - 1)
expect_object("m", mean(x), message = "`m <- mean(x)`.")
expect_object("se", se, message = "SE = SD / √n: `sd(x) / sqrt(length(x))`.")
expect_object("t_crit", tc,
              message = "`qt(0.975, df = length(x) - 1)`: the t value with 2.5% above it, on n − 1 = 39 df.")
expect_object("ci_by_hand", c(mean(x) - tc * se, mean(x) + tc * se),
              message = "Two numbers, lower then upper: `c(m - t_crit * se, m + t_crit * se)`.")
ci <- get_object("ci_r")
expect_true(isTRUE(all.equal(as.numeric(ci), as.numeric(t.test(x)$conf.int))),
            label = "`ci_r` is t.test()'s interval",
            message = "`t.test(x)$conf.int`.")
expect_called("qt")
