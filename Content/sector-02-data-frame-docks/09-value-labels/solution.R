# 1. Import the SPSS file
library(haven)
teach <- read_sav("teaching_study.sav")

# 2. Every labelled column as a factor
teach_f <- as_factor(teach)

# 3. How many had Active learning?
n_active <- sum(teach_f$method == "Active learning")

# 4. How many anxiety answers are missing?
n_no_answer <- sum(is.na(teach$anxiety))

# 5. Mean anxiety (1-5) of those who answered
mean_anxiety <- mean(teach$anxiety, na.rm = TRUE)
