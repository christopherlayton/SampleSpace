# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# 2. Centre and spread in one summary
centre <- astronauts |>
  summarise()

# 3. The longest mission
longest <- 

# 4. The APA sentence
apa <- sprintf("Mission length was positively skewed (Mdn = %.0f h, ...).", centre$median_hours)
apa
