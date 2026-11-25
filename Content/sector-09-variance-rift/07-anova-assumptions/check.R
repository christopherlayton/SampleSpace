pd0 <- utils::read.csv("pd_study.csv")
pd0$programme <- factor(pd0$programme)
fit0 <- aov(efficacy_t2 ~ programme, data = pd0)
lv0 <- car::leveneTest(efficacy_t2 ~ programme, data = pd0, center = mean)
lv <- get_object("levene")
expect_true(is.data.frame(lv) && isTRUE(all.equal(lv$"F value"[1], lv0$"F value"[1])),
            label = "`levene` is Levene's test centred on the mean",
            message = "`leveneTest(efficacy_t2 ~ programme, data = pd, center = mean)`: car centres on the median unless told otherwise.")
sw0 <- shapiro.test(residuals(fit0))
sw <- get_object("shapiro")
expect_true(inherits(sw, "htest") && isTRUE(all.equal(unname(sw$statistic), unname(sw0$statistic))),
            label = "`shapiro` tests the residuals",
            message = "`shapiro.test(residuals(fit))`: the residuals, not the raw scores.")
expect_called("qqnorm", message = "Draw the Q–Q plot: `qqnorm(residuals(fit))`.")
expect_called("qqline", message = "Add the reference line: `qqline(residuals(fit))`.")
w0 <- oneway.test(efficacy_t2 ~ programme, data = pd0)
w <- get_object("welch")
expect_true(inherits(w, "htest") && isTRUE(all.equal(unname(w$statistic), unname(w0$statistic))) &&
              isTRUE(all.equal(unname(w$parameter), unname(w0$parameter))),
            label = "`welch` is Welch's ANOVA",
            message = "`oneway.test(efficacy_t2 ~ programme, data = pd)`, leaving `var.equal` at its default (FALSE).")
k0 <- kruskal.test(efficacy_t2 ~ programme, data = pd0)
k <- get_object("kruskal")
expect_true(inherits(k, "htest") && isTRUE(all.equal(unname(k$statistic), unname(k0$statistic))),
            label = "`kruskal` is the Kruskal–Wallis test", message = "`kruskal.test(efficacy_t2 ~ programme, data = pd)`.")
