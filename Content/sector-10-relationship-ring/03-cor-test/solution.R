library(ggplot2)
sleep <- read.csv("sleep_morale.csv")

# 1. Plot first
p <- ggplot(sleep, aes(x = sleep_hours, y = morale_score)) +
  geom_point()
p

# 2. Pearson's r with its df and CI
pearson <- cor.test(sleep$sleep_hours, sleep$morale_score)
pearson
r <- unname(pearson$estimate)
df <- unname(pearson$parameter)
ci <- pearson$conf.int

# 3. Shared variance
r_squared <- r^2

# 4. Spearman's rho
spearman <- cor.test(sleep$sleep_hours, sleep$morale_score, method = "spearman", exact = FALSE)
spearman
