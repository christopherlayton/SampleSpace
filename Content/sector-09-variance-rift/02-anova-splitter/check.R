pd0 <- utils::read.csv("pd_study.csv")
fit0 <- aov(efficacy_t2 ~ programme, data = pd0)
tab0 <- summary(fit0)[[1]]
n_l <- get_object("n")
expect_true(is.numeric(n_l) && length(n_l) == 3 && all(n_l == 20), label = "`n` holds each programme's size",
            message = "`n <- tapply(pd$efficacy_t2, pd$programme, length)`: 20 teachers in each programme.")
expect_object("ss_between", tab0$"Sum Sq"[1], tolerance = 1e-6,
              message = "SS between: `sum(n * (means - grand)^2)`, each group's squared distance from the grand mean, times its size.")
expect_object("ss_within", tab0$"Sum Sq"[2], tolerance = 1e-6,
              message = "SS within: `sum((pd$efficacy_t2 - means[pd$programme])^2)`, each score's squared distance from its own group mean.")
expect_object("f", tab0$"F value"[1], tolerance = 1e-6,
              message = "F is MS between over MS within: `(ss_between / 2) / (ss_within / 57)`.")
expect_object("p", tab0$"Pr(>F)"[1], tolerance = 1e-8,
              message = "The upper tail of the F distribution: `pf(f, 2, 57, lower.tail = FALSE)`.")
expect_object("eta_sq", tab0$"Sum Sq"[1] / sum(tab0$"Sum Sq"), tolerance = 1e-6,
              message = "η² is SS between over SS total: `ss_between / (ss_between + ss_within)`.")
expect_called("aov", message = "Finish by checking your numbers with `summary(aov(efficacy_t2 ~ programme, data = pd))`.")
