# 1. Packages and the SPSS file
library(haven)
library(effectsize)
teach <- read_sav("teaching_study.sav")
teach$method <- as_factor(teach$method)

# 2. The two groups and the pooled SD
lecture <- teach$score[teach$method == "Lecture"]
active <- 
sd_pooled <- 

# 3. Cohen's d by hand (Lecture - Active learning)
d_hand <- 

# 4. The same with effectsize, and its CI
d_pkg <- 
d_ci <- 
