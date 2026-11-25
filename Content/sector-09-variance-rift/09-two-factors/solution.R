library(afex)
library(dplyr)
library(effectsize)
library(ggplot2)
pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))

# 1. Cell means
cells <- pd |>
  group_by(programme, experience) |>
  summarise(n = n(), mean = mean(efficacy_t2), .groups = "drop")
cells

# 2. Factorial ANOVA with aov()
fit2 <- aov(efficacy_t2 ~ programme * experience, data = pd)
summary(fit2)

# 3. The same with afex (Type III, like SPSS)
factorial <- aov_car(efficacy_t2 ~ programme * experience + Error(id), data = pd)
anova(factorial, es = "pes")

# 4. Partial eta squared
pes <- eta_squared(fit2, partial = TRUE)
pes

# 5. Interaction plot
p <- ggplot(cells, aes(x = programme, y = mean, colour = experience, group = experience)) +
  geom_point() +
  geom_line()
p
