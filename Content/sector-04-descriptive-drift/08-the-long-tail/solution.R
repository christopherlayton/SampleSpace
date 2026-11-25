# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# 2. Centre and spread in one summary
centre <- astronauts |>
  summarise(mean_hours = mean(hours_mission),
            median_hours = median(hours_mission),
            sd_hours = sd(hours_mission),
            iqr_hours = IQR(hours_mission))

# 3. The longest mission
longest <- astronauts |>
  slice_max(hours_mission, n = 1) |>
  select(name, year_of_mission, hours_mission)

# 4. The APA sentence
apa <- sprintf("Mission length was positively skewed (Mdn = %.0f h, IQR = %.0f h; M = %.0f h, SD = %.0f h).",
               centre$median_hours, centre$iqr_hours, centre$mean_hours, centre$sd_hours)
apa
