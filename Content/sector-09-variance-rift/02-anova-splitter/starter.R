pd <- read.csv("pd_study.csv")
grand <- mean(pd$efficacy_t2)

# 1. Group means and sizes
means <- tapply(pd$efficacy_t2, pd$programme, mean)
n <- 

# 2. Sums of squares
ss_between <- 
ss_within <- 

# 3. F and p
f <- 
p <- 

# 4. Eta squared
eta_sq <- 

# 5. Compare with aov()

