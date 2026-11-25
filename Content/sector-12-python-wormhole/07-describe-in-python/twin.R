library(readr)
log <- read_csv("astronauts.csv", show_col_types = FALSE)
hours <- log$hours_mission
c(mean = mean(hours), median = median(hours), sd = sd(hours))
psych::describe(hours, type = 2)[c("n", "mean", "sd", "skew", "kurtosis")]
IQR(hours)
