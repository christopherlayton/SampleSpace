# 1. The quiz numbers
my_score <- 68
class_mean <- 60
class_sd <- 5

# 2. Your z-score
z <- (my_score - class_mean) / class_sd

# 3. Your classmate's z-score (they scored 52)
z_classmate <- (52 - class_mean) / class_sd

# 4. Print z rounded to 2 decimals
round(z, digits = 2)
