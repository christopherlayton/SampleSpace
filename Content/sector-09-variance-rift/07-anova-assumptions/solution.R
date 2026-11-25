library(car)
pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))
fit <- aov(efficacy_t2 ~ programme, data = pd)

# 1. Levene's test, centred like SPSS
levene <- leveneTest(efficacy_t2 ~ programme, data = pd, center = mean)
levene

# 2. Normality of the residuals: Shapiro-Wilk and a Q-Q plot
shapiro <- shapiro.test(residuals(fit))
shapiro
qqnorm(residuals(fit))
qqline(residuals(fit))

# 3. Welch's ANOVA and Kruskal-Wallis
welch <- oneway.test(efficacy_t2 ~ programme, data = pd)
kruskal <- kruskal.test(efficacy_t2 ~ programme, data = pd)
welch
kruskal
