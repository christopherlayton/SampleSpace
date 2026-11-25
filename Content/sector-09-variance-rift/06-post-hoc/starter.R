pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))
fit <- aov(efficacy_t2 ~ programme, data = pd)

# 1. Tukey HSD
tukey <- 

# 2. Pairwise t-tests, Bonferroni and Holm
pairs_bonf <- 
pairs_holm <- 

# 3. Which pairs differ (Tukey, p adj < .05)?
differ <- 
