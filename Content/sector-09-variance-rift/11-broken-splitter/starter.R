library(readr)
pd <- read_csv("pd_study.csv", show_col_types = FALSE)
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))
pd$group_code <- as.numeric(pd$programme)   # 1, 2, 3, as in the SPSS file

# One-way ANOVA of self-efficacy at the end by programme
fit <- aov(efficacy_t2 ~ group_code, data = pd)
summary(fit)

# Which programmes differ?
tukey <- TukeyHSD(summary(fit))
tukey

# Equal variances?
levene <- leveneTest(efficacy_t2 ~ programme, data = pd, center = mean)
levene

# Effect size
tab <- summary(fit)[[1]]
eta_sq <- tab$"Sum Sq"[1] / tab$"Sum Sq"[2]
eta_sq
