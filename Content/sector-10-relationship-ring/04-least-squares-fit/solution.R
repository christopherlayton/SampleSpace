library(readr)
d <- read_csv("sleep_morale.csv", show_col_types = FALSE)

# 1. Regression of morale on sleep
fit <- lm(morale_score ~ sleep_hours, data = d)

# 2. Intercept and slope
b <- coef(fit)
b

# 3. Sum of squared residuals, and total sum of squares
sse <- sum(residuals(fit)^2)
sst <- sum((d$morale_score - mean(d$morale_score))^2)

# 4. R-squared from the two sums
r2 <- 1 - sse / sst
r2
