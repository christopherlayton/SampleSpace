library(haven)
library(effectsize)
teach <- read_sav("teaching_study.sav")
teach$method <- as_factor(teach$method)
lecture <- teach$score[teach$method == "Lecture"]
active <- teach$score[teach$method == "Active learning"]

# 1. Welch's t-test and Cohen's d
res <- 
d <- 

# 2. APA p-values: "= .011" or "< .001"
fmt_p <- function(p) {
  
}

# 3. The results sentence
apa <- sprintf(paste("Students taught with active learning (M = %.2f, SD = %.2f) scored higher than",
                     "students taught by lecture (M = %.2f, SD = %.2f), t(%.2f) = %.2f, p %s, d = %.2f."),
               )
apa
