s0 <- utils::read.csv("sleep_morale.csv")
m0 <- lm(morale_score ~ sleep_hours, data = s0)
m <- get_object("model")
expect_true(inherits(m, "lm") && isTRUE(all.equal(unname(coef(m)), unname(coef(m0)))),
            label = "`model` regresses morale on sleep",
            message = "`lm(morale_score ~ sleep_hours, data = sleep)`: the outcome goes on the left of `~`.")
expect_object("b", unname(coef(m0)[2]), tolerance = 1e-10, check_attributes = FALSE,
              message = "`unname(coef(model)[\"sleep_hours\"])`.")
expect_object("b_ci", unname(confint(m0)[2, ]), tolerance = 1e-10, check_attributes = FALSE,
              message = "`confint(model)[\"sleep_hours\", ]`.")
expect_object("r_squared", summary(m0)$r.squared, tolerance = 1e-10, message = "`summary(model)$r.squared`.")
expect_object("pred_8", unname(coef(m0)[1] + 8 * coef(m0)[2]), tolerance = 1e-10, check_attributes = FALSE,
              message = "`predict(model, newdata = data.frame(sleep_hours = 8))`.")
expect_object("beta", cor(s0$sleep_hours, s0$morale_score), tolerance = 1e-8, check_attributes = FALSE,
              message = "Scale both variables: `coef(lm(scale(morale_score) ~ scale(sleep_hours), data = sleep))[2]`.")
