library(readr)
library(dplyr)
library(car)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. First missions, with age and decade
first <- astronauts |>
  filter(mission_number == 1) |>
  mutate(age = year_of_mission - year_of_birth,
         decade = factor(floor(year_of_mission / 10) * 10))

# 2. n, mean and sd of age per decade
decade_stats <- first |>
  group_by(decade) |>
  summarise(n = n(), mean = mean(age), sd = sd(age))
decade_stats

# 3. Levene's test (SPSS-style)
levene <- leveneTest(age ~ decade, data = first, center = mean)
levene

# 4. Classic and Welch's ANOVA
classic <- aov(age ~ decade, data = first)
welch <- oneway.test(age ~ decade, data = first)
summary(classic)
welch

# 5. Effect size and Games-Howell post hoc tests
eta <- eta_squared(classic)
games <- rstatix::games_howell_test(first, age ~ decade)
eta
games

# 6. Which test fits, and your decision at alpha = .05
test_used <- if (levene$"Pr(>F)"[1] < 0.05) "welch" else "classic"
p_used <- if (test_used == "welch") welch$p.value else summary(classic)[[1]]$"Pr(>F)"[1]
decision <- if (p_used < 0.05) "reject" else "fail to reject"
c(test_used = test_used, decision = decision)
