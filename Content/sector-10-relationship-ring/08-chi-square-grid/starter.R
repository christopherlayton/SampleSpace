counts <- matrix(c(28, 22,
                   20, 30), nrow = 2, byrow = TRUE,
                 dimnames = list(method = c("Lecture", "Active learning"),
                                 result = c("Passed", "Did not pass")))
counts

# 1. Pearson's chi-square (no correction) and the expected counts
pearson <- 
expected <- 

# 2. Pearson residuals
resid <- 

# 3. Cramer's V by hand
v <- 

# 4. R's default (Yates) and Fisher's exact test
yates <- 
fisher <- 
