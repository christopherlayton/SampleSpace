s <- utils::read.csv("wellbeing_survey.csv")
ctrl <- s$anxiety_post[s$group == "Control"]
mind <- s$anxiety_post[s$group == "Mindfulness"]
same_values <- function(x, want) is.numeric(x) && length(x) == length(want) &&
  isTRUE(all.equal(sort(x, na.last = TRUE), sort(want, na.last = TRUE)))
expect_true(same_values(get_object("mindful"), mind), label = "`mindful` holds the Mindfulness group's post-test scores",
            message = "Same as `control`, with `\"Mindfulness\"`.")
expect_object("sw_control", shapiro.test(ctrl)$p.value, message = "`shapiro.test(control)$p.value`.")
expect_object("sw_mindful", shapiro.test(mind)$p.value, message = "`shapiro.test(mindful)$p.value`.")
f_of <- function(x) if (is.data.frame(x) && "F value" %in% names(x)) x$"F value"[1] else NA
lv_med <- car::leveneTest(anxiety_post ~ factor(group), data = s)
lv_mean <- car::leveneTest(anxiety_post ~ factor(group), data = s, center = mean)
expect_true(isTRUE(all.equal(f_of(get_object("levene_median")), lv_med$"F value"[1])),
            label = "`levene_median` is car's default Levene test",
            message = "`leveneTest(anxiety_post ~ factor(group), data = survey)`.")
expect_true(isTRUE(all.equal(f_of(get_object("levene_mean")), lv_mean$"F value"[1])),
            label = "`levene_mean` matches SPSS",
            message = "Add `center = mean`: SPSS centres Levene's test on the group means.")
expect_object("levene_p", lv_mean$"Pr(>F)"[1], message = "`levene_mean$\"Pr(>F)\"[1]`: about .041.")
expect_called("shapiro.test")
expect_called("qqnorm")
expect_called("qqline")
expect_plot(message = "`qqnorm(control)` then `qqline(control)`.")
