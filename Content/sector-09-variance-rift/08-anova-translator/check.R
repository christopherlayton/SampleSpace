pd0 <- utils::read.csv("pd_study.csv")
pd0$programme <- factor(pd0$programme, levels = c("Workshop", "Coaching", "Online"))
y0 <- pd0$efficacy_t2
d <- get_object("desc")
ok_d <- is.data.frame(d) && nrow(d) == 3 && all(c("n", "mean", "sd", "se") %in% names(d))
expect_true(ok_d && isTRUE(all.equal(as.numeric(d$mean), as.numeric(tapply(y0, pd0$programme, mean)))) &&
              isTRUE(all.equal(as.numeric(d$se), as.numeric(tapply(y0, pd0$programme, sd)) / sqrt(20))),
            label = "`desc` matches SPSS's Descriptives (N, Mean, Std. Deviation, Std. Error)",
            message = "`summarise(n = n(), mean = mean(efficacy_t2), sd = sd(efficacy_t2), se = sd / sqrt(n))` per programme, in SPSS's order.")
lm0 <- car::leveneTest(efficacy_t2 ~ programme, data = pd0, center = mean)
lmd0 <- car::leveneTest(efficacy_t2 ~ programme, data = pd0, center = median)
a <- get_object("levene_mean")
b <- get_object("levene_median")
expect_true(is.data.frame(a) && isTRUE(all.equal(a$"F value"[1], lm0$"F value"[1])),
            label = "`levene_mean` is the Based on Mean row (1.813)", message = "`leveneTest(efficacy_t2 ~ programme, data = pd, center = mean)`.")
expect_true(is.data.frame(b) && isTRUE(all.equal(b$"F value"[1], lmd0$"F value"[1])),
            label = "`levene_median` is the Based on Median row (1.776)", message = "The same with `center = median`.")
f <- get_object("fit")
expect_true(inherits(f, "aov") && isTRUE(all.equal(summary(f)[[1]]$"Sum Sq",
                                                    summary(aov(efficacy_t2 ~ programme, data = pd0))[[1]]$"Sum Sq")),
            label = "`fit` gives the ANOVA table", message = "`fit <- aov(efficacy_t2 ~ programme, data = pd)`.")
w0 <- oneway.test(efficacy_t2 ~ programme, data = pd0)
w <- get_object("welch")
expect_true(inherits(w, "htest") && isTRUE(all.equal(unname(w$statistic), unname(w0$statistic))),
            label = "`welch` is the Robust Test (Welch, 4.765)", message = "`oneway.test(efficacy_t2 ~ programme, data = pd)`.")
t <- get_object("tukey")
expect_true(inherits(t, "TukeyHSD") && !is.null(t$programme) && nrow(t$programme) == 3,
            label = "`tukey` is Tukey's HSD", message = "`tukey <- TukeyHSD(fit)`.")
