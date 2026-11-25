a0 <- utils::read.csv("astronauts.csv")
f0 <- a0[a0$mission_number == 1, ]
f0$age <- f0$year_of_mission - f0$year_of_birth
f0$decade <- factor(floor(f0$year_of_mission / 10) * 10)
fl <- get_object("first")
ok_f <- is.data.frame(fl) && nrow(fl) == nrow(f0) && all(c("age", "decade") %in% names(fl))
expect_true(ok_f && is.factor(fl$decade) && nlevels(fl$decade) == 6 && isTRUE(all.equal(sort(fl$age), sort(f0$age))),
            label = "`first` has one row per astronaut, with `age` and a 6-level `decade` factor",
            message = paste("`filter(mission_number == 1)`, then `mutate(age = year_of_mission - year_of_birth,",
                            "decade = factor(floor(year_of_mission / 10) * 10))`."))
ds <- get_object("decade_stats")
expect_true(is.data.frame(ds) && nrow(ds) == 6 && all(c("n", "mean", "sd") %in% names(ds)) &&
              isTRUE(all.equal(as.numeric(ds$mean), as.numeric(tapply(f0$age, f0$decade, mean)))) &&
              isTRUE(all.equal(as.numeric(ds$sd), as.numeric(tapply(f0$age, f0$decade, sd)))),
            label = "`decade_stats` describes each decade",
            message = "`first |> group_by(decade) |> summarise(n = n(), mean = mean(age), sd = sd(age))`.")
lv0 <- car::leveneTest(age ~ decade, data = f0, center = mean)
lv <- get_object("levene")
expect_true(is.data.frame(lv) && isTRUE(all.equal(lv$"F value"[1], lv0$"F value"[1])),
            label = "`levene` is Levene's test centred on the mean",
            message = "`leveneTest(age ~ decade, data = first, center = mean)`.")
c0 <- aov(age ~ decade, data = f0)
cl <- get_object("classic")
expect_true(inherits(cl, "aov") && isTRUE(all.equal(summary(cl)[[1]]$"F value"[1], summary(c0)[[1]]$"F value"[1])) &&
              identical(summary(cl)[[1]]$Df, summary(c0)[[1]]$Df),
            label = "`classic` is the one-way ANOVA of age by decade",
            message = "`aov(age ~ decade, data = first)`, with `decade` a factor.")
w0 <- oneway.test(age ~ decade, data = f0)
w <- get_object("welch")
expect_true(inherits(w, "htest") && isTRUE(all.equal(unname(w$statistic), unname(w0$statistic))),
            label = "`welch` is Welch's ANOVA", message = "`oneway.test(age ~ decade, data = first)`.")
e <- get_object("eta")
tab0 <- summary(c0)[[1]]
expect_true(inherits(e, "effectsize_table") && isTRUE(all.equal(e$Eta2[1], tab0$"Sum Sq"[1] / sum(tab0$"Sum Sq"))),
            label = "`eta` is η² for decade", message = "`eta_squared(classic)`.")
g <- get_object("games")
expect_true(inherits(g, "games_howell_test") && nrow(g) == choose(6, 2),
            label = "`games` holds Games–Howell comparisons for all 15 pairs of decades",
            message = "`rstatix::games_howell_test(first, age ~ decade)`.")
used0 <- if (lv0$"Pr(>F)"[1] < 0.05) "welch" else "classic"
expect_object("test_used", used0,
              message = "Let Levene decide: p below .05 points to Welch's ANOVA (\"welch\"); otherwise the classic F (\"classic\").")
p0 <- if (used0 == "welch") w0$p.value else tab0$"Pr(>F)"[1]
expect_object("decision", if (p0 < 0.05) "reject" else "fail to reject",
              message = "Compare the p-value of the test you chose with .05: below it, \"reject\"; otherwise \"fail to reject\".")
