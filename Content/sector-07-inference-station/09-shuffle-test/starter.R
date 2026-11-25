library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- astronauts |> filter(mission_number == 1)
era <- ifelse(first$year_of_mission >= 2000, "2000 on", "before 2000")
woman <- first$sex == "female"

# 1. The observed gap: proportion of women, 2000 on minus before 2000
observed <- 

# 2. 5,000 gaps with the era labels shuffled
shuffled <- replicate(5000, {
  
})

# 3. Two-sided p-value
p_shuffle <- 

# 4. Decision at alpha = .05: "reject" or "fail to reject"
decision <- 

# 5. The null distribution and the observed gap

