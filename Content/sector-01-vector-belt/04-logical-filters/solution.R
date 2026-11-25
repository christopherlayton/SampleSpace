scores <- c(55, 72, 64, 89, 47, 91, 68, 76)

# 1. Did each student pass (60 or more)?
passed <- scores >= 60

# 2. How many passed?
n_passed <- sum(passed)

# 3. What proportion passed?
prop_passed <- mean(passed)

# 4. Only the scores of 80 or more
high_scores <- scores[scores >= 80]
