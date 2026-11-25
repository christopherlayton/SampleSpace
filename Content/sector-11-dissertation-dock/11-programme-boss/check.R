ref <- utils::read.csv("pd_study.csv")
ref$programme <- factor(ref$programme, levels = c("Workshop", "Coaching", "Online"))
ref$gain <- ref$efficacy_t3 - ref$efficacy_t1
ref_fit <- aov(gain ~ programme, data = ref)
ref_table <- summary(ref_fit)[[1]]
ref_eta <- ref_table$"Sum Sq"[1] / sum(ref_table$"Sum Sq")
is_df <- function(x) is.data.frame(x)

step(1)
p <- get_object("pd")
expect_true(is_df(p) && nrow(p) == 60 && is.factor(p$programme) &&
              identical(levels(p$programme), c("Workshop", "Coaching", "Online")),
            label = "`programme` is a factor: Workshop, Coaching, Online",
            message = "`mutate(programme = factor(programme, levels = c(\"Workshop\", \"Coaching\", \"Online\")))`. Without `levels`, R sorts them alphabetically.")
expect_true(is_df(p) && "gain" %in% names(p) && isTRUE(all.equal(as.numeric(p$gain), ref$gain)),
            label = "`gain` is follow-up minus before",
            message = "`gain = efficacy_t3 - efficacy_t1`: later minus earlier, so a positive gain is an improvement.")

step(2)
gs <- get_object("group_stats")
ok <- is_df(gs) && nrow(gs) == 3 && all(c("programme", "n", "M", "SD") %in% names(gs))
expect_true(ok && isTRUE(all.equal(as.numeric(gs$M[order(as.character(gs$programme))]),
                                   as.numeric(tapply(ref$gain, as.character(ref$programme), mean)))) &&
              isTRUE(all.equal(as.numeric(gs$SD[order(as.character(gs$programme))]),
                               as.numeric(tapply(ref$gain, as.character(ref$programme), sd)))),
            label = "`group_stats` has n, M and SD of gain per programme",
            message = "`pd |> group_by(programme) |> summarise(n = n(), M = mean(gain), SD = sd(gain))`.")

step(3)
lv <- car::leveneTest(gain ~ programme, data = ref, center = mean)
l <- get_object("levene")
expect_true(is_df(l) && isTRUE(all.equal(l$"F value"[1], lv$"F value"[1])), label = "`levene` is SPSS's Levene test",
            message = "`leveneTest(gain ~ programme, data = pd, center = mean)`.")
f <- get_object("fit")
expect_true(inherits(f, "aov") && isTRUE(all.equal(unname(fitted(f)), unname(fitted(ref_fit)))),
            label = "`fit` is the one-way ANOVA of gain by programme", message = "`fit <- aov(gain ~ programme, data = pd)`.")
rc <- get_object("residual_check")
expect_true(inherits(rc, "htest") && isTRUE(all.equal(unname(rc$statistic), unname(shapiro.test(residuals(ref_fit))$statistic))),
            label = "`residual_check` tests the residuals for normality",
            message = "`shapiro.test(residuals(fit))`: the model's residuals, not the raw scores.")

step(4)
at <- get_object("anova_table")
expect_true(is_df(at) && "F value" %in% names(at) && isTRUE(all.equal(at$"F value"[1], ref_table$"F value"[1])),
            label = "`anova_table` is the ANOVA table", message = "`summary(fit)[[1]]`.")
e <- get_object("eta2")
expect_true(inherits(e, "effectsize_table") && isTRUE(all.equal(e$Eta2[1], ref_eta)),
            label = "`eta2` is η²", message = "`eta_squared(fit)` from effectsize.")

step(5)
tk <- get_object("tukey")
expect_true(inherits(tk, "TukeyHSD") && isTRUE(all.equal(tk$programme[, "p adj"], TukeyHSD(ref_fit)$programme[, "p adj"])),
            label = "`tukey` holds Tukey's HSD comparisons", message = "`TukeyHSD(fit)`.")

step(6)
expect_ggplot("fig", aes = c(x = "programme", y = "gain"))
fg <- get_object("fig")
expect_true(inherits(fg, "ggplot") && length(fg$layers) > 0, label = "`fig` draws the gains",
            message = "Add a layer, e.g. `+ geom_boxplot()`.")
expect_true(inherits(fg, "ggplot") && !is.null(gg_label(fg, "y")) && gg_label(fg, "y") != "gain" &&
              !is.null(gg_label(fg, "x")) && gg_label(fg, "x") != "programme",
            label = "The axes have readable labels",
            message = "`labs(x = \"Programme\", y = \"Change in self-efficacy\")`.")

step(7)
expect_object("decision", if (ref_table$"Pr(>F)"[1] < .05) "reject" else "fail to reject",
              message = "Compare the ANOVA's p with .05: below it, \"reject\"; otherwise \"fail to reject\".")
wu <- get_object("write_up")
if (!is.character(wu) || length(wu) != 1) wu <- ""
expect_apa(wu, list(stat = "F", df = ref_table$Df, value = ref_table$"F value"[1], p = ref_table$"Pr(>F)"[1]), c(eta2 = ref_eta))
tk_ref <- TukeyHSD(ref_fit)$programme
sig <- rownames(tk_ref)[tk_ref[, "p adj"] < .05]
singled <- names(which(table(unlist(strsplit(sig, "-"))) == 2))
expect_true(length(singled) == 0 || all(vapply(singled, function(s) grepl(s, wu, fixed = TRUE), TRUE)),
            label = "The write-up names the programme the post hoc tests single out",
            message = "Read `tukey`: which programme differs from both others? Name it in the sentence.")
