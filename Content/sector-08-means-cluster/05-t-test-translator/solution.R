# 1. Packages and the SPSS file
library(haven)
library(car)
teach <- read_sav("teaching_study.sav")
teach$method <- as_factor(teach$method)

# 2. Levene's test and the two t-test rows
levene <- leveneTest(score ~ method, data = teach, center = mean)
student <- t.test(score ~ method, data = teach, var.equal = TRUE)
welch <- t.test(score ~ method, data = teach)
levene
student
welch

# 3. Three numbers from the SPSS table
levene_f <- levene$"F value"[1]
welch_df <- unname(welch$parameter)
p_one_sided <- student$p.value / 2
