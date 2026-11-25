# 1. Load haven and import the file
library(haven)
teach <- read_sav("teaching_study.sav")

# 2. How many students?
n_students <- nrow(teach)

# 3. Mean exam score
mean_score <- mean(teach$score)

# 4. How many students had each teaching method? (labels, not codes)
method_counts <- table(as_factor(teach$method))
