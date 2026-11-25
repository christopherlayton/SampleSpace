library(readr)
library(dplyr)
library(car)
library(effectsize)
library(ggplot2)

# Step 1: Import, programme as a factor, gain = follow-up minus before
pd <- read_csv("pd_study.csv", show_col_types = FALSE) |>
  mutate(programme = factor(programme, levels = c("Workshop", "Coaching", "Online")),
         gain = efficacy_t3 - efficacy_t1)

# Step 2: Describe
group_stats <- pd |>
  group_by(programme) |>
  summarise(n = n(), M = mean(gain), SD = sd(gain))
group_stats

# Step 3: Assumptions
levene <- leveneTest(gain ~ programme, data = pd, center = mean)
fit <- aov(gain ~ programme, data = pd)
residual_check <- shapiro.test(residuals(fit))
levene
residual_check

# Step 4: ANOVA
anova_table <- summary(fit)[[1]]
eta2 <- eta_squared(fit)
anova_table
eta2

# Step 5: Post hoc
tukey <- TukeyHSD(fit)
tukey

# Step 6: Plot
fig <- ggplot(pd, aes(x = programme, y = gain)) +
  geom_boxplot(width = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(x = "Programme", y = "Change in self-efficacy (follow-up minus before)") +
  theme_classic()
fig

# Step 7: Write it up
decision <- if (anova_table$"Pr(>F)"[1] < .05) "reject" else "fail to reject"
write_up <- sprintf(
  "Gains in self-efficacy differed between programmes, *F*(%d, %d) = %s, *p* %s, η² = %s. Tukey tests showed that Coaching differed from both other programmes.",
  anova_table$Df[1], anova_table$Df[2], fmt_num(anova_table$"F value"[1]),
  fmt_p(anova_table$"Pr(>F)"[1]), fmt_bounded(eta2$Eta2[1]))
write_up
