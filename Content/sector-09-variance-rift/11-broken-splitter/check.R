pd0 <- utils::read.csv("pd_study.csv")
pd0$programme <- factor(pd0$programme, levels = c("Workshop", "Coaching", "Online"))
tab0 <- summary(aov(efficacy_t2 ~ programme, data = pd0))[[1]]
f <- get_object("fit")
expect_true(inherits(f, "aov") && identical(summary(f)[[1]]$Df, tab0$Df) &&
              isTRUE(all.equal(summary(f)[[1]]$"F value"[1], tab0$"F value"[1])),
            label = "`fit` compares the three programmes (2 df between groups)",
            message = "Use the factor, not the number: `aov(efficacy_t2 ~ programme, data = pd)`. A numeric code gives 1 df.")
t <- get_object("tukey")
expect_true(inherits(t, "TukeyHSD") && !is.null(t$programme) && nrow(t$programme) == 3,
            label = "`tukey` compares every pair of programmes",
            message = "`TukeyHSD(fit)`: the model, not its summary, and fitted on `programme`.")
lv0 <- car::leveneTest(efficacy_t2 ~ programme, data = pd0, center = mean)
l <- get_object("levene")
expect_true(is.data.frame(l) && isTRUE(all.equal(l$"F value"[1], lv0$"F value"[1])),
            label = "`levene` is Levene's test centred on the mean",
            message = "Load car with `library(car)` so `leveneTest()` can be found.")
expect_object("eta_sq", tab0$"Sum Sq"[1] / sum(tab0$"Sum Sq"), tolerance = 1e-8,
              message = "η² = SS between ÷ SS total: `tab$\"Sum Sq\"[1] / sum(tab$\"Sum Sq\")`.")
