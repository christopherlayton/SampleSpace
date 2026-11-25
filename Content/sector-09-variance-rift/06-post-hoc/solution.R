pd <- read.csv("pd_study.csv")
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))
fit <- aov(efficacy_t2 ~ programme, data = pd)

# 1. Tukey HSD
tukey <- TukeyHSD(fit)
tukey$programme

# 2. Pairwise t-tests, Bonferroni and Holm
pairs_bonf <- pairwise.t.test(pd$efficacy_t2, pd$programme, p.adjust.method = "bonferroni")
pairs_holm <- pairwise.t.test(pd$efficacy_t2, pd$programme, p.adjust.method = "holm")
pairs_bonf
pairs_holm

# 3. Which pairs differ (Tukey, p adj < .05)?
differ <- rownames(tukey$programme)[tukey$programme[, "p adj"] < 0.05]
differ
