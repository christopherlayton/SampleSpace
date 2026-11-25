# 1. Set the seed, then a random crew of 10 ID numbers (1 to 564)
set.seed(2026)
crew_ids <- sample(1:564, size = 10)
crew_ids

# 2. 600 rolls of a six-sided die
rolls <- sample(1:6, size = 600, replace = TRUE)

# 3. The proportion of sixes
prop_six <- mean(rolls == 6)
prop_six

# 4. How often did each face come up?
table(rolls)
