agree <- c(4, 2, 5, 3, 4, 1, 5, 4)
likert_labels <- c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree")

# 1. An ordered factor with labels
agree_f <- factor(agree, levels = 1:5, labels = likert_labels, ordered = TRUE)

# 2. How many answered Agree or higher?
n_agree <- sum(agree_f >= "Agree")
