library(dplyr)
library(effectsize)
pd <- read.csv("pd_study.csv")

# 1. Programme as a factor: Workshop, Coaching, Online
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))

# 2. n, mean and sd of efficacy_t2 per programme
group_stats <- pd |>
  group_by(programme) |>
  summarise(n = n(), mean = mean(efficacy_t2), sd = sd(efficacy_t2))
group_stats

# 3. One-way ANOVA
fit <- aov(efficacy_t2 ~ programme, data = pd)
summary(fit)

# 4. F and p from the ANOVA table
tab <- summary(fit)[[1]]
f_value <- tab$"F value"[1]
p_value <- tab$"Pr(>F)"[1]

# 5. Eta squared
eta <- eta_squared(fit)
eta
