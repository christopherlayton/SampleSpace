library(dplyr)
library(effectsize)
pd <- read.csv("pd_study.csv")

# 1. Programme as a factor: Workshop, Coaching, Online
pd$programme <- 

# 2. n, mean and sd of efficacy_t2 per programme
group_stats <- 

# 3. One-way ANOVA
fit <- 

# 4. F and p from the ANOVA table
tab <- summary(fit)[[1]]
f_value <- 
p_value <- 

# 5. Eta squared
eta <- 
