t0 <- haven::read_sav("teaching_study.sav")
t0$method <- haven::as_factor(t0$method)
lv <- car::leveneTest(score ~ method, data = t0, center = mean)
st <- t.test(score ~ method, data = t0, var.equal = TRUE)
we <- t.test(score ~ method, data = t0)
tm <- get_object("teach")
expect_true(is.data.frame(tm) && is.factor(tm$method) && identical(levels(tm$method), levels(t0$method)),
            label = "`teach$method` is a factor of the value labels",
            message = "`teach$method <- as_factor(teach$method)` turns codes 1 and 2 into Lecture and Active learning.")
l <- get_object("levene")
expect_true(is.data.frame(l) && isTRUE(all.equal(l$"F value"[1], lv$"F value"[1])),
            label = "`levene` matches SPSS's Levene test (F = .625)",
            message = "`leveneTest(score ~ method, data = teach, center = mean)`: SPSS centres on the mean.")
same_t <- function(x, want) inherits(x, "htest") && isTRUE(all.equal(unname(x$statistic), unname(want$statistic))) &&
  isTRUE(all.equal(unname(x$parameter), unname(want$parameter)))
expect_true(same_t(get_object("student"), st), label = "`student` is the equal-variances row (df = 28)",
            message = "`t.test(score ~ method, data = teach, var.equal = TRUE)`.")
expect_true(same_t(get_object("welch"), we), label = "`welch` is the unequal-variances row (df = 25.094)",
            message = "`t.test(score ~ method, data = teach)`: Welch's test is R's default.")
expect_object("levene_f", lv$"F value"[1], message = "`levene$\"F value\"[1]`.")
expect_object("welch_df", unname(we$parameter), message = "`unname(welch$parameter)`.")
expect_object("p_one_sided", st$p.value / 2,
              message = "SPSS's one-sided p is half the two-sided one: `student$p.value / 2` (about .005).")
