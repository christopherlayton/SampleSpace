truth <- utils::read.csv("sleep_morale.csv")
want <- lm(morale_score ~ sleep_hours, data = truth)
f <- get_object("fit")
expect_true(inherits(f, "lm") && isTRUE(all.equal(unname(coef(f)), unname(coef(want)))),
            label = "`fit` regresses morale on sleep",
            message = "Outcome first: `lm(morale_score ~ sleep_hours, data = d)`.")
expect_object("b", coef(want), message = "`b <- coef(fit)` gives the intercept and the slope.")
expect_object("sse", sum(residuals(want)^2), message = "Square the residuals and add them: `sum(residuals(fit)^2)`.")
expect_object("sst", sum((truth$morale_score - mean(truth$morale_score))^2),
              message = "Squared distances of morale from its mean: `sum((d$morale_score - mean(d$morale_score))^2)`.")
expect_object("r2", summary(want)$r.squared, message = "`r2 <- 1 - sse / sst`.")
