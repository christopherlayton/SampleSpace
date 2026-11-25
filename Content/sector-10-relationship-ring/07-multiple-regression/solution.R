library(car)
library(effectsize)
pd <- read.csv("pd_study.csv")

# 1. Block 1 and the full model
base <- lm(efficacy_t3 ~ efficacy_t1, data = pd)
model <- lm(efficacy_t3 ~ efficacy_t1 + workload_hours + years_teaching, data = pd)
summary(model)

# 2. R squared, adjusted R squared, and the change from block 1
r2 <- summary(model)$r.squared
adj_r2 <- summary(model)$adj.r.squared
r2_change <- r2 - summary(base)$r.squared

# 3. Does block 2 add significantly?
change_test <- anova(base, model)
change_test

# 4. Standardised coefficients and VIFs
betas <- standardize_parameters(model)
vifs <- vif(model)
betas
vifs

# 5. Diagnostic plots
plot(model, which = 1)
plot(model, which = 2)
