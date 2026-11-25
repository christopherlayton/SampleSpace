library(haven)
library(effectsize)
teach <- read_sav("teaching_study.sav")
teach$method <- as_factor(teach$method)
lecture <- teach$score[teach$method == "Lecture"]
active <- teach$score[teach$method == "Active learning"]

# 1. Welch's t-test and Cohen's d
res <- t.test(score ~ method, data = teach)
d <- cohens_d(score ~ method, data = teach)

# 2. APA p-values: "= .011" or "< .001"
fmt_p <- function(p) {
  if (p < 0.001) "< .001" else paste("=", sub("^0", "", sprintf("%.3f", p)))
}

# 3. The results sentence
apa <- sprintf(paste("Students taught with active learning (M = %.2f, SD = %.2f) scored higher than",
                     "students taught by lecture (M = %.2f, SD = %.2f), t(%.2f) = %.2f, p %s, d = %.2f."),
               mean(active), sd(active), mean(lecture), sd(lecture),
               unname(res$parameter), abs(unname(res$statistic)), fmt_p(res$p.value), abs(d$Cohens_d))
apa
