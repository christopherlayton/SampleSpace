pd0 <- utils::read.csv("pd_study.csv")
rt <- get_object("r_test")
expect_true(inherits(rt, "htest") && grepl("Pearson", rt$method) &&
              isTRUE(all.equal(unname(rt$estimate), cor(pd0$efficacy_t1, pd0$efficacy_t3))),
            label = "`r_test` tests the correlation of efficacy_t1 and efficacy_t3",
            message = "`cor.test(~ efficacy_t1 + efficacy_t3, data = pd)`: nothing on the left of `~`.")
m0 <- lm(efficacy_t3 ~ efficacy_t1 + workload_hours, data = pd0)
m <- get_object("model")
expect_true(inherits(m, "lm") && identical(names(m$model)[1], "efficacy_t3") &&
              isTRUE(all.equal(unname(coef(m)[names(coef(m0))]), unname(coef(m0)))),
            label = "`model` predicts efficacy_t3 from efficacy_t1 and workload_hours",
            message = "The outcome goes on the left: `lm(efficacy_t3 ~ efficacy_t1 + workload_hours, data = pd)`.")
expect_object("vifs", car::vif(m0), tolerance = 1e-8, message = "Load car (`library(car)`), then `vif(model)`.")
x0 <- chisq.test(table(pd0$programme, pd0$experience))
ch <- get_object("chi")
expect_true(inherits(ch, "htest") && isTRUE(all.equal(unname(ch$statistic), unname(x0$statistic))) &&
              isTRUE(all.equal(unname(ch$parameter), 2)),
            label = "`chi` is the χ² test of programme by experience (2 df)",
            message = "Give `chisq.test()` counts: `chisq.test(table(pd$programme, pd$experience))`.")
