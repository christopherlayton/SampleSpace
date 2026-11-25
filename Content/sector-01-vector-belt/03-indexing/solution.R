reaction <- c(512, 468, 590, 433, 615, 507)   # trial 1 is a practice trial

# 1. The first trial
first_trial <- reaction[1]

# 2. The last trial (use length())
last_trial <- reaction[length(reaction)]

# 3. Every trial except the practice trial
real_trials <- reaction[-1]

# 4. Trials 2 to 5
middle_trials <- reaction[2:5]
