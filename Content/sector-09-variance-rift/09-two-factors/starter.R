library(afex)
library(dplyr)
library(effectsize)
library(ggplot2)
pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))

# 1. Cell means
cells <- 

# 2. Factorial ANOVA with aov()
fit2 <- 

# 3. The same with afex (Type III, like SPSS)
factorial <- 

# 4. Partial eta squared
pes <- 

# 5. Interaction plot
p <- 
p
