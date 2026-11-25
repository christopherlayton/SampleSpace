library(readr)
library(dplyr)
library(car)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. One row per astronaut: status and mean hours per mission
people <- astronauts |>
  group_by(number) |>
  summarise(military_civilian = first(military_civilian),
            mean_hours = mean(hours_mission))

# 2. Describe each group: n, mean, sd, median of mean_hours
group_stats <- people |>
  group_by(military_civilian) |>
  summarise(n = n(), mean = mean(mean_hours), sd = sd(mean_hours), median = median(mean_hours))
group_stats

# 3. Levene (SPSS-style), Welch's t-test and Cohen's d
levene <- leveneTest(mean_hours ~ factor(military_civilian), data = people, center = mean)
welch <- t.test(mean_hours ~ military_civilian, data = people)
d <- cohens_d(mean_hours ~ military_civilian, data = people)
levene
welch
d

# 4. Decision at alpha = .05
decision <- if (welch$p.value < 0.05) "reject" else "fail to reject"
decision
