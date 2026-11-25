library(readr)
library(dplyr)
library(ggplot2)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. One row per astronaut, with a three-way nation grouping
people <- astronauts |>
  group_by(number) |>
  summarise(missions = n(),
            eva_hours = sum(eva_hrs_mission),
            military_civilian = first(military_civilian),
            nationality = first(nationality)) |>
  mutate(nation = case_when(nationality %in% c("U.S.", "U.S.S.R/Russia") ~ nationality,
                            .default = "Other"))

# 2. Plot first
p <- ggplot(people, aes(x = missions, y = eva_hours)) +
  geom_jitter(width = 0.15, height = 0, alpha = 0.5)
p

# 3. Missions and EVA hours: Pearson and Spearman
pearson <- cor.test(people$missions, people$eva_hours)
spearman <- cor.test(people$missions, people$eva_hours, method = "spearman", exact = FALSE)
pearson
spearman

# 4. Regression of EVA hours on missions
model <- lm(eva_hours ~ missions, data = people)
summary(model)
b <- unname(coef(model)["missions"])

# 5. Nation by military status
crosstab <- table(people$nation, people$military_civilian)
chi <- chisq.test(crosstab)
v <- cramers_v(crosstab, adjust = FALSE)
crosstab
chi
v

# 6. Decisions at alpha = .05
decision_r <- if (pearson$p.value < 0.05) "reject" else "fail to reject"
decision_chi <- if (chi$p.value < 0.05) "reject" else "fail to reject"
c(decision_r = decision_r, decision_chi = decision_chi)
