participant <- c("P1", "P2", "P3", "P4", "P5", "P6")
gender      <- c(1, 2, 2, 1, 3, 1)
education   <- c("HS", "BA", "MA", "BA", "PhD", "HS")
wellbeing   <- c(32, 41, 38, NA, 45, 36)

# 1. Nominal: gender as a labelled factor
gender_f <- factor(gender, levels = 1:3, labels = c("Woman", "Man", "Non-binary"))

# 2. Ordinal: education as an ordered factor (HS < BA < MA < PhD)
education_f <- factor(education, levels = c("HS", "BA", "MA", "PhD"), ordered = TRUE)

# 3. Interval: mean wellbeing
mean_wellbeing <- mean(wellbeing, na.rm = TRUE)
