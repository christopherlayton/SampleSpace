# 1. The crew log
library(readr)
astronauts <- read_csv("astronauts.csv")
hours <- astronauts$hours_mission

# 2. SD and variance
sd_hours <- sd(hours)
var_hours <- var(hours)

# 3. Interquartile range
iqr_hours <- IQR(hours)

# 4. 90th percentile
p90_hours <- as.numeric(quantile(hours, 0.9))

# 5. Range
range_hours <- range(hours)
