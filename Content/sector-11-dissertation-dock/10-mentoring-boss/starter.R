library(haven)
library(dplyr)
library(car)
library(effectsize)
library(ggplot2)

# Step 1: Import
study <- read_sav("belonging_study.sav")

# Step 2: Score (reverse b2 and b4; mean of the items, needing at least 4 answered)
scored <- study
analysed <- scored
alpha <- NA

# Step 3: Describe
group_stats <- NULL

# Step 4: Assumptions
levene <- NULL
normality <- NULL

# Step 5: Test
welch <- NULL
d <- NULL

# Step 6: Plot
fig <- NULL

# Step 7: Write it up
decision <- ""
write_up <- ""
write_up
