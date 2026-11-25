# 1. Import and convert the labels
library(haven)
teach <- read_sav("teaching_study.sav")
teach_f <- as_factor(teach)

# 2. Frequency: teaching method
method_counts <- table(teach_f$method)

# 3. Missing anxiety answers
n_missing <- sum(is.na(teach_f$anxiety))

# 4. Percent: anxiety (of all cases)
anxiety_pct <- round(100 * table(teach_f$anxiety) / nrow(teach_f), 1)

# 5. Valid Percent: anxiety (of the answered cases)
anxiety_valid <- round(100 * prop.table(table(teach_f$anxiety)), 1)
