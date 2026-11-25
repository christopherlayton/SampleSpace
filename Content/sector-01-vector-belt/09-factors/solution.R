condition <- c("control", "treatment", "treatment", "control",
               "waitlist", "treatment", "control")

# 1. A factor with levels: control, waitlist, treatment
condition_f <- factor(condition, levels = c("control", "waitlist", "treatment"))

# 2. How many conditions?
n_conditions <- nlevels(condition_f)

# 3. How many participants in each condition?
condition_counts <- table(condition_f)
