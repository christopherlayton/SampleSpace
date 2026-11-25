library(readr)
library(dplyr)
library(ggplot2)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. One row per astronaut, with a three-way nation grouping
people <- astronauts |>
  group_by(number) |>
  summarise()

# 2. Plot first
p <- 
p

# 3. Missions and EVA hours: Pearson and Spearman
pearson <- 
spearman <- 

# 4. Regression of EVA hours on missions
model <- 
b <- 

# 5. Nation by military status
crosstab <- 
chi <- 
v <- 

# 6. Decisions at alpha = .05
decision_r <- 
decision_chi <- 
