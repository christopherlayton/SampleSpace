pd0 <- utils::read.csv("pd_study.csv")
lg <- get_object("long")
ok_l <- is.data.frame(lg) && nrow(lg) == 180 && all(c("id", "time", "efficacy") %in% names(lg))
expect_true(ok_l && isTRUE(all.equal(sort(lg$efficacy), sort(c(pd0$efficacy_t1, pd0$efficacy_t2, pd0$efficacy_t3)))),
            label = "`long` has one row per teacher per time (180 rows)",
            message = "`pivot_longer(starts_with(\"efficacy\"), names_to = \"time\", values_to = \"efficacy\")`.")
tm <- get_object("time_means")
expect_true(is.data.frame(tm) && nrow(tm) == 3 && "mean" %in% names(tm) &&
              isTRUE(all.equal(sort(as.numeric(tm$mean)), sort(colMeans(pd0[, c("efficacy_t1", "efficacy_t2", "efficacy_t3")])),
                               check.attributes = FALSE)),
            label = "`time_means` has the mean at each time",
            message = "`long |> group_by(time) |> summarise(mean = mean(efficacy))`.")
long0 <- data.frame(id = rep(pd0$id, 3), time = rep(c("t1", "t2", "t3"), each = nrow(pd0)),
                    efficacy = c(pd0$efficacy_t1, pd0$efficacy_t2, pd0$efficacy_t3))
rm0 <- suppressMessages(afex::aov_ez(id = "id", dv = "efficacy", data = long0, within = "time"))
r <- get_object("rm")
expect_true(inherits(r, "afex_aov") && isTRUE(all.equal(r$anova_table$F, rm0$anova_table$F)) &&
              isTRUE(all.equal(r$anova_table$"num Df", rm0$anova_table$"num Df")),
            label = "`rm` is the repeated-measures ANOVA, Greenhouse–Geisser corrected",
            message = "`aov_ez(id = \"id\", dv = \"efficacy\", data = long, within = \"time\")`.")
expect_object("mauchly_p", unname(summary(rm0)$sphericity.tests[, "p-value"]), tolerance = 1e-8, check_attributes = FALSE,
              message = "`summary(rm)$sphericity.tests[, \"p-value\"]`.")
fu <- get_object("follow_up")
expect_true(inherits(fu, "pairwise.htest") && identical(fu$p.adjust.method, "holm") && grepl("paired", fu$method) &&
              isTRUE(all.equal(sort(as.numeric(na.omit(c(fu$p.value)))),
                               sort(as.numeric(na.omit(c(pairwise.t.test(long0$efficacy, long0$time, paired = TRUE)$p.value)))))),
            label = "`follow_up` is Holm-corrected paired t-tests",
            message = "`pairwise.t.test(long$efficacy, long$time, paired = TRUE, p.adjust.method = \"holm\")`.")
