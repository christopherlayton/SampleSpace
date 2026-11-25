library(haven)
library(effectsize)
teach <- read_sav("teaching_study.sav")
teach$method <- as_factor(teach$method)

# 1. Passed: score of 70 or more
teach$passed <- 

# 2. Crosstabulation
tab <- 

# 3. Pearson, Continuity Correction and Fisher's Exact Test
pearson <- 
yates <- 
fisher <- 

# 4. Likelihood Ratio
g2 <- 

# 5. Phi and Cramer's V (unadjusted, as SPSS reports them)
phi_value <- 
v <- 
