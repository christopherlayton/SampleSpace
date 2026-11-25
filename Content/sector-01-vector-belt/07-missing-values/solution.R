sleep_hours <- c(7, 6.5, NA, 8, 5.5, NA, 7.5, 6)

mean(sleep_hours)   # try running this first: why NA?

# 1. How many are missing?
n_missing <- sum(is.na(sleep_hours))

# 2. How many valid answers?
n_valid <- sum(!is.na(sleep_hours))

# 3. Mean sleep of those who answered
mean_sleep <- mean(sleep_hours, na.rm = TRUE)
