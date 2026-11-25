library(haven)
library(dplyr)
library(car)
library(effectsize)
library(ggplot2)

# Step 1: Import
study <- read_sav("belonging_study.sav") |>
  mutate(condition = as_factor(condition), first_gen = as_factor(first_gen))

# Step 2: Score
scored <- study |>
  mutate(across(b1:b5, zap_labels),
         b2 = 6 - b2, b4 = 6 - b4,
         answered = rowSums(!is.na(pick(b1:b5))),
         belonging = if_else(answered >= 4, rowMeans(pick(b1:b5), na.rm = TRUE), NA))
analysed <- filter(scored, !is.na(belonging))
alpha <- psych::alpha(select(analysed, b1:b5))$total$raw_alpha
alpha

# Step 3: Describe
group_stats <- analysed |>
  group_by(condition) |>
  summarise(n = n(), M = mean(belonging), SD = sd(belonging))
group_stats

# Step 4: Assumptions
levene <- leveneTest(belonging ~ condition, data = analysed, center = mean)
normality <- analysed |>
  group_by(condition) |>
  summarise(W = shapiro.test(belonging)$statistic, p = shapiro.test(belonging)$p.value)
levene
normality

# Step 5: Test
welch <- t.test(belonging ~ condition, data = analysed)
d <- cohens_d(belonging ~ condition, data = analysed)
welch
d

# Step 6: Plot
fig <- ggplot(analysed, aes(x = condition, y = belonging)) +
  geom_boxplot(width = 0.5) +
  geom_jitter(width = 0.1, alpha = 0.5) +
  labs(x = "Condition", y = "Sense of belonging (1-5)") +
  theme_classic()
fig

# Step 7: Write it up
decision <- if (welch$p.value < .05) "reject" else "fail to reject"
ctrl <- filter(group_stats, condition == "Control")
peer <- filter(group_stats, condition == "Peer mentoring")
write_up <- sprintf(
  "Students with a peer mentor (*M* = %s, *SD* = %s) and controls (*M* = %s, *SD* = %s): *t*(%s) = %s, *p* %s, *d* = %s.",
  fmt_num(peer$M), fmt_num(peer$SD), fmt_num(ctrl$M), fmt_num(ctrl$SD),
  fmt_num(welch$parameter), fmt_num(welch$statistic), fmt_p(welch$p.value), fmt_num(d$Cohens_d))
write_up
