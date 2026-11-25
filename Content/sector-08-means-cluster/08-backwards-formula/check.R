s <- utils::read.csv("wellbeing_survey.csv")
expect_no_error(message = "R still stops with an error. Fix the first one it reports, then run again.")
g <- get_object("groups_test")
want_g <- t.test(anxiety_post ~ group, data = s)
expect_true(inherits(g, "htest") && isTRUE(all.equal(unname(g$statistic), unname(want_g$statistic))),
            label = "`groups_test` compares anxiety_post by group",
            message = "Outcome on the left, group on the right: `t.test(anxiety_post ~ group, data = survey)`.")
l <- get_object("levene")
want_l <- car::leveneTest(anxiety_post ~ factor(group), data = s, center = mean)
expect_true(is.data.frame(l) && isTRUE(all.equal(l$"F value"[1], want_l$"F value"[1])),
            label = "`levene` is SPSS's Levene test",
            message = "`leveneTest()` is in the car package: add `library(car)` near the top.")
ch <- get_object("change_test")
want_c <- t.test(s$anxiety_pre, s$anxiety_post, paired = TRUE)
expect_true(inherits(ch, "htest") && isTRUE(all.equal(unname(ch$statistic), unname(want_c$statistic))),
            label = "`change_test` is a paired test",
            message = paste("The same students took both tests, so the test must be paired: add `paired = TRUE`.",
                            "Without it R runs a two-group test, which gives an answer, just the wrong one."))
dd <- get_object("d")
want_d <- effectsize::cohens_d(anxiety_post ~ group, data = s)
expect_true(inherits(dd, "effectsize_table") && isTRUE(all.equal(dd$Cohens_d, want_d$Cohens_d)),
            label = "`d` is Cohen's d for the groups",
            message = "`cohens_d()` needs to know where the columns are: add `data = survey`.")
