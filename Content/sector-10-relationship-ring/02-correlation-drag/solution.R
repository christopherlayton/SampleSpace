# Twenty points with no real relationship
x <- rnorm(20, mean = 5, sd = 1.3)
y <- rnorm(20, mean = 5, sd = 1.3)

# 1. Pearson's r
r_cloud <- cor(x, y)

# 2. Add an outlier at (9.6, 0.4)
x2 <- c(x, 9.6)
y2 <- c(y, 0.4)

# 3. Pearson's r and Spearman's rho with the outlier
r_outlier <- cor(x2, y2)
rho_outlier <- cor(x2, y2, method = "spearman")
c(r_cloud = r_cloud, r_outlier = r_outlier, rho_outlier = rho_outlier)

# 4. Plot it
plot(x2, y2)
