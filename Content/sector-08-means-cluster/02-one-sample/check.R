x <- utils::read.csv("wellbeing_survey.csv")$anxiety_pre
want <- t.test(x, mu = 28)
r <- get_object("res")
expect_true(inherits(r, "htest") && isTRUE(all.equal(unname(r$statistic), unname(want$statistic))),
            label = "`res` is the one-sample t-test against 28",
            message = "`t.test(survey$anxiety_pre, mu = 28)`. Without `mu`, R tests against 0.")
expect_object("t_val", unname(want$statistic), check_attributes = TRUE,
              message = "`unname(res$statistic)`: the number without its \"t\" label.")
expect_object("df_val", unname(want$parameter), check_attributes = TRUE,
              message = "`unname(res$parameter)`: n − 1 = 39.")
expect_object("p_val", want$p.value, message = "`res$p.value`.")
ci <- get_object("ci")
expect_true(isTRUE(all.equal(as.numeric(ci), as.numeric(want$conf.int))),
            label = "`ci` is the 95% CI", message = "`res$conf.int`.")
md <- get_object("mean_diff")
expect_true(isTRUE(all.equal(as.numeric(md), mean(x) - 28)) && length(md) == 1,
            label = "`mean_diff` is M − 28", message = "`mean(survey$anxiety_pre) - 28`, or `res$estimate - 28`.")
