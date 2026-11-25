library(car)
pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))
fit <- aov(efficacy_t2 ~ programme, data = pd)

# 1. Levene's test, centred like SPSS
levene <- 

# 2. Normality of the residuals: Shapiro-Wilk and a Q-Q plot
shapiro <- 


# 3. Welch's ANOVA and Kruskal-Wallis
welch <- 
kruskal <- 
