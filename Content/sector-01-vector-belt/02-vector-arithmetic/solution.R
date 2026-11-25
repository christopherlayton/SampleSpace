raw <- c(34, 41, 28, 45, 38)   # quiz scores out of 50

# 1. Each score as a percentage
percent <- raw / 50 * 100

# 2. Mean-centred scores
centred <- raw - mean(raw)
