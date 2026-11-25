library(dplyr)
library(car)
pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))

# 1. Descriptives: n, mean, sd and se per programme
desc <- pd |>
  group_by(programme) |>
  summarise(n = n(), mean = mean(efficacy_t2), sd = sd(efficacy_t2), se = sd / sqrt(n))
desc

# 2. Tests of Homogeneity of Variances: mean and median rows
levene_mean <- leveneTest(efficacy_t2 ~ programme, data = pd, center = mean)
levene_median <- leveneTest(efficacy_t2 ~ programme, data = pd, center = median)
levene_mean
levene_median

# 3. ANOVA table
fit <- aov(efficacy_t2 ~ programme, data = pd)
summary(fit)

# 4. Robust test (Welch) and Tukey HSD
welch <- oneway.test(efficacy_t2 ~ programme, data = pd)
tukey <- TukeyHSD(fit)
welch
tukey
