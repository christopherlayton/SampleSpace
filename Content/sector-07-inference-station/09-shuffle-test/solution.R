library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- astronauts |> filter(mission_number == 1)
era <- ifelse(first$year_of_mission >= 2000, "2000 on", "before 2000")
woman <- first$sex == "female"

# 1. The observed gap: proportion of women, 2000 on minus before 2000
observed <- mean(woman[era == "2000 on"]) - mean(woman[era == "before 2000"])

# 2. 5,000 gaps with the era labels shuffled
shuffled <- replicate(5000, {
  e <- sample(era)
  mean(woman[e == "2000 on"]) - mean(woman[e == "before 2000"])
})

# 3. Two-sided p-value
p_shuffle <- mean(abs(shuffled) >= abs(observed))
p_shuffle

# 4. Decision at alpha = .05: "reject" or "fail to reject"
decision <- if (p_shuffle < 0.05) "reject" else "fail to reject"

# 5. The null distribution and the observed gap
hist(shuffled)
abline(v = observed)
