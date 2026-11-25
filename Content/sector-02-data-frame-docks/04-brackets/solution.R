# study is already loaded. Take a look:
head(study)

# 1. Row 3
row_three <- study[3, ]

# 2. The score column (with brackets)
all_scores <- study[, "score"]

# 3. Treatment-group rows only
treatment_only <- study[study$condition == "treatment", ]

# 4. id and score for participants aged 25 or over
older_scores <- study[study$age >= 25, c("id", "score")]
