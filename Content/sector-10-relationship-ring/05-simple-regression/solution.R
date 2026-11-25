sleep <- read.csv("sleep_morale.csv")

# 1. Regression of morale on sleep
model <- lm(morale_score ~ sleep_hours, data = sleep)
summary(model)

# 2. The slope and its 95% CI
b <- unname(coef(model)["sleep_hours"])
b_ci <- confint(model)["sleep_hours", ]

# 3. R squared
r_squared <- summary(model)$r.squared

# 4. Predicted morale at 8 hours of sleep
pred_8 <- unname(predict(model, newdata = data.frame(sleep_hours = 8)))

# 5. Standardised slope
beta <- unname(coef(lm(scale(morale_score) ~ scale(sleep_hours), data = sleep))[2])
c(b = b, r_squared = r_squared, pred_8 = pred_8, beta = beta, r = cor(sleep$sleep_hours, sleep$morale_score))
