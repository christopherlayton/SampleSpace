# The reference analysis
raw <- haven::read_sav("belonging_study.sav")
cond <- haven::as_factor(raw$condition)
items <- as.data.frame(lapply(raw[, c("b1", "b2", "b3", "b4", "b5")], function(x) as.numeric(haven::zap_labels(x))))
items$b2 <- 6 - items$b2
items$b4 <- 6 - items$b4
answered <- rowSums(!is.na(items))
score <- ifelse(answered >= 4, rowMeans(items, na.rm = TRUE), NA)
keep <- !is.na(score)
ref <- data.frame(condition = cond[keep], belonging = score[keep])
ref_t <- t.test(belonging ~ condition, data = ref)
ref_d <- effectsize::cohens_d(belonging ~ condition, data = ref)$Cohens_d
ref_alpha <- suppressMessages(suppressWarnings(psych::alpha(items[keep, ])$total$raw_alpha))
is_df <- function(x) is.data.frame(x)

step(1)
st <- get_object("study")
expect_true(is_df(st) && nrow(st) == 84 && all(c("condition", "first_gen", paste0("b", 1:5)) %in% names(st)),
            label = "`study` holds all 84 students", message = "`study <- read_sav(\"belonging_study.sav\")`.")
expect_true(is_df(st) && is.factor(st$condition) && identical(levels(st$condition), c("Control", "Peer mentoring")) &&
              is.factor(st$first_gen),
            label = "`condition` and `first_gen` are factors with their SPSS labels",
            message = "`mutate(condition = as_factor(condition), first_gen = as_factor(first_gen))`, so the groups are called Control and Peer mentoring, not 1 and 2.")

step(2)
sc <- get_object("scored")
ok_sc <- is_df(sc) && nrow(sc) == 84 && "belonging" %in% names(sc)
expect_true(ok_sc && isTRUE(all.equal(as.numeric(sc$belonging), as.numeric(score))),
            label = "`scored$belonging` is the mean of the five items, b2 and b4 reversed",
            message = paste("Reverse b2 and b4 with `6 - x` before averaging, then",
                            "`if_else(answered >= 4, rowMeans(pick(b1:b5), na.rm = TRUE), NA)`."))
an <- get_object("analysed")
expect_true(is_df(an) && nrow(an) == sum(keep) && !anyNA(an$belonging),
            label = "`analysed` keeps the students with a scale score",
            message = sprintf("%d students answered at least four items. `analysed <- filter(scored, !is.na(belonging))`.", sum(keep)))
expect_object("alpha", ref_alpha, tolerance = 1e-4, label = "`alpha` is Cronbach's α of the scored items",
              message = "`psych::alpha(select(analysed, b1:b5))$total$raw_alpha`, after reversing b2 and b4 (otherwise α comes out far too low).")

step(3)
gs <- get_object("group_stats")
want_m <- tapply(ref$belonging, ref$condition, mean)
ok_gs <- is_df(gs) && nrow(gs) == 2 && all(c("condition", "n", "M", "SD") %in% names(gs))
expect_true(ok_gs && isTRUE(all.equal(as.numeric(gs$M[order(as.character(gs$condition))]), as.numeric(want_m))) &&
              isTRUE(all.equal(as.numeric(gs$SD[order(as.character(gs$condition))]), as.numeric(tapply(ref$belonging, ref$condition, sd)))) &&
              isTRUE(all.equal(as.numeric(gs$n[order(as.character(gs$condition))]), as.numeric(table(ref$condition)))),
            label = "`group_stats` has n, M and SD per condition",
            message = "`analysed |> group_by(condition) |> summarise(n = n(), M = mean(belonging), SD = sd(belonging))`.")

step(4)
lv <- car::leveneTest(belonging ~ condition, data = ref, center = mean)
l <- get_object("levene")
expect_true(is_df(l) && isTRUE(all.equal(l$"F value"[1], lv$"F value"[1])), label = "`levene` is SPSS's Levene test",
            message = "`leveneTest(belonging ~ condition, data = analysed, center = mean)`.")
nm <- get_object("normality")
want_w <- tapply(ref$belonging, ref$condition, function(x) shapiro.test(x)$statistic)
expect_true(is_df(nm) && nrow(nm) == 2 && "W" %in% names(nm) &&
              isTRUE(all.equal(sort(as.numeric(nm$W)), sort(as.numeric(want_w)))),
            label = "`normality` has Shapiro–Wilk's W for each group",
            message = "`group_by(condition) |> summarise(W = shapiro.test(belonging)$statistic, p = shapiro.test(belonging)$p.value)`.")

step(5)
w <- get_object("welch")
expect_true(inherits(w, "htest") && isTRUE(all.equal(unname(w$statistic), unname(ref_t$statistic))) &&
              isTRUE(all.equal(unname(w$parameter), unname(ref_t$parameter))),
            label = "`welch` is Welch's t-test of belonging by condition",
            message = "`t.test(belonging ~ condition, data = analysed)`: Welch is R's default.")
dl <- get_object("d")
expect_true(inherits(dl, "effectsize_table") && isTRUE(all.equal(dl$Cohens_d, ref_d)),
            label = "`d` is Cohen's d", message = "`cohens_d(belonging ~ condition, data = analysed)`.")

step(6)
expect_ggplot("fig", geom = "boxplot", aes = c(x = "condition", y = "belonging"))
fg <- get_object("fig")
expect_true(inherits(fg, "ggplot") && !is.null(gg_label(fg, "y")) && gg_label(fg, "y") != "belonging" &&
              !is.null(gg_label(fg, "x")) && gg_label(fg, "x") != "condition",
            label = "The axes have readable labels",
            message = "`labs(x = \"Condition\", y = \"Sense of belonging (1-5)\")`: a reader shouldn't see variable names.")

step(7)
expect_object("decision", if (ref_t$p.value < .05) "reject" else "fail to reject",
              message = "Compare Welch's p with .05: below it, \"reject\"; otherwise \"fail to reject\".")
wu <- get_object("write_up")
if (!is.character(wu) || length(wu) != 1) wu <- ""
fm <- function(x) formatC(x, format = "f", digits = 2)
expect_true(all(vapply(c(fm(want_m), fm(tapply(ref$belonging, ref$condition, sd))), function(v) grepl(v, wu, fixed = TRUE), TRUE)),
            label = "The write-up gives each group's *M* and *SD*",
            message = "Describe both groups in the sentence, two decimals: (*M* = …, *SD* = …).")
expect_apa(wu, ref_t, c(d = ref_d))
