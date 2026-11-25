library(car)
pd <- read.csv("pd_study.csv")

# Does starting self-efficacy go with self-efficacy at follow-up?
r_test <- cor.test(~ efficacy_t1 + efficacy_t3, data = pd)
r_test

# Predict follow-up self-efficacy from starting self-efficacy and workload
model <- lm(efficacy_t3 ~ efficacy_t1 + workload_hours, data = pd)
summary(model)
vifs <- vif(model)
vifs

# Were early-career and experienced teachers spread evenly across programmes?
chi <- chisq.test(table(pd$programme, pd$experience))
chi
