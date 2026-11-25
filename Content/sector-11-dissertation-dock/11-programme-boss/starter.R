library(readr)
library(dplyr)
library(car)
library(effectsize)
library(ggplot2)

# Step 1: Import, programme as a factor, gain = follow-up minus before
pd <- read_csv("pd_study.csv", show_col_types = FALSE)

# Step 2: Describe
group_stats <- NULL

# Step 3: Assumptions
levene <- NULL
fit <- NULL
residual_check <- NULL

# Step 4: ANOVA
anova_table <- NULL
eta2 <- NULL

# Step 5: Post hoc
tukey <- NULL

# Step 6: Plot
fig <- NULL

# Step 7: Write it up
decision <- ""
write_up <- ""
write_up
