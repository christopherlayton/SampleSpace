library(dplyr)
library(car)
pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))

# 1. Descriptives: n, mean, sd and se per programme
desc <- 

# 2. Tests of Homogeneity of Variances: mean and median rows
levene_mean <- 
levene_median <- 

# 3. ANOVA table
fit <- 

# 4. Robust test (Welch) and Tukey HSD
welch <- 
tukey <- 
