pd0 <- utils::read.csv("pd_study.csv")
order0 <- c("Workshop", "Coaching", "Online")
pd0$programme <- factor(pd0$programme, levels = order0)
fit0 <- aov(efficacy_t2 ~ programme, data = pd0)
tab0 <- summary(fit0)[[1]]
expect_true(is.factor(pd$programme) && identical(levels(pd$programme), order0),
            label = "`programme` is a factor: Workshop, Coaching, Online",
            message = "`pd$programme <- factor(pd$programme, levels = c(\"Workshop\", \"Coaching\", \"Online\"))`.")
gs <- get_object("group_stats")
ok_gs <- is.data.frame(gs) && nrow(gs) == 3 && all(c("programme", "n", "mean", "sd") %in% names(gs))
expect_true(ok_gs && isTRUE(all.equal(as.numeric(gs$mean), as.numeric(tapply(pd0$efficacy_t2, pd0$programme, mean)))) &&
              isTRUE(all.equal(as.numeric(gs$sd), as.numeric(tapply(pd0$efficacy_t2, pd0$programme, sd)))) &&
              all(gs$n == 20),
            label = "`group_stats` has n, mean and sd per programme, in order",
            message = "`pd |> group_by(programme) |> summarise(n = n(), mean = mean(efficacy_t2), sd = sd(efficacy_t2))`, after step 1.")
f <- get_object("fit")
expect_true(inherits(f, "aov") && isTRUE(all.equal(summary(f)[[1]]$"F value"[1], tab0$"F value"[1])) &&
              identical(summary(f)[[1]]$Df, tab0$Df),
            label = "`fit` is the one-way ANOVA of efficacy_t2 by programme",
            message = "`fit <- aov(efficacy_t2 ~ programme, data = pd)`: outcome on the left of `~`.")
expect_object("f_value", tab0$"F value"[1], tolerance = 1e-8, message = "`tab$\"F value\"[1]`: the programme row.")
expect_object("p_value", tab0$"Pr(>F)"[1], tolerance = 1e-10, message = "`tab$\"Pr(>F)\"[1]`.")
e <- get_object("eta")
expect_true(inherits(e, "effectsize_table") && isTRUE(all.equal(e$Eta2[1], tab0$"Sum Sq"[1] / sum(tab0$"Sum Sq"))),
            label = "`eta` is η² for programme", message = "`eta <- eta_squared(fit)`.")
