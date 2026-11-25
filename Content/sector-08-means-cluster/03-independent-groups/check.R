s <- utils::read.csv("wellbeing_survey.csv")
w <- t.test(anxiety_post ~ group, data = s)
st <- t.test(anxiety_post ~ group, data = s, var.equal = TRUE)
same_test <- function(x, want) inherits(x, "htest") && isTRUE(all.equal(unname(x$statistic), unname(want$statistic))) &&
  isTRUE(all.equal(unname(x$parameter), unname(want$parameter)))
expect_true(same_test(get_object("welch"), w), label = "`welch` is Welch's t-test of anxiety_post by group",
            message = "`t.test(anxiety_post ~ group, data = survey)`: outcome on the left of `~`, group on the right.")
expect_true(same_test(get_object("student"), st), label = "`student` is Student's t-test",
            message = "Add `var.equal = TRUE` for Student's version.")
expect_object("welch_df", unname(w$parameter), message = "`unname(welch$parameter)`: about 29.3, not a whole number.")
expect_object("p_welch", w$p.value, message = "`welch$p.value`.")
d <- get_object("diff_means")
expect_true(length(d) == 1 && isTRUE(all.equal(as.numeric(d), unname(w$estimate[1] - w$estimate[2]))),
            label = "`diff_means` is Control − Mindfulness",
            message = "`welch$estimate` holds the means in the order Control, Mindfulness: subtract the second from the first.")
