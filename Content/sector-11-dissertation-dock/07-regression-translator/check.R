truth <- read.csv("sleep_morale.csv")
m <- lm(morale_score ~ sleep_hours, data = truth)
s <- summary(m)
fl <- get_object("fit")
expect_true(inherits(fl, "lm") && isTRUE(all.equal(unname(coef(fl)), unname(coef(m)))),
            label = "`fit` is the regression of morale on sleep",
            message = "`lm(morale_score ~ sleep_hours, data = sm)`: outcome on the left of the `~`.")
expect_true(inherits(get_object("fit_summary"), "summary.lm"), label = "`fit_summary` is `summary(fit)`",
            message = "`fit_summary <- summary(fit)`.")
want_beta <- coef(m)[[2]] * sd(truth$sleep_hours) / sd(truth$morale_score)
expect_object("beta", want_beta, tolerance = 1e-4, label = "`beta` is SPSS's standardized Beta (.489)",
              message = "Beta = *b* × *SD*(sleep) / *SD*(morale). With one predictor it equals *r*.")
f <- s$fstatistic
want_p <- pf(f[["value"]], f[["numdf"]], f[["dendf"]], lower.tail = FALSE)
expect_object("p", want_p, tolerance = 1e-6, label = "`p` is the model's exact p-value",
              message = "`pf(F, df1, df2, lower.tail = FALSE)` with the pieces of `fit_summary$fstatistic`, not SPSS's rounded .001.")
wu <- get_object("write_up")
if (!is.character(wu)) wu <- ""
expect_apa(wu, list(stat = "F", df = c(1, 44), value = f[["value"]], p = want_p), c(R2 = s$r.squared))
bm <- regmatches(gsub("[*_]", "", wu), regexec("(?:^|[^A-Za-z])b\\s*=\\s*(-?[0-9]*\\.[0-9]+)", gsub("[*_]", "", wu), perl = TRUE))[[1]]
expect_true(length(bm) == 2 && identical(bm[2], formatC(coef(m)[[2]], format = "f", digits = 2)),
            label = "The slope is reported: *b* = 0.70",
            message = "End with the slope from `coef(fit)`, two decimals: *b* = 0.70.")
