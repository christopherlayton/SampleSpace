ages_text <- c("21", "34", "19", "42", "twenty-five", "28")
consent_text <- c("TRUE", "TRUE", "FALSE", "TRUE", "TRUE", "FALSE")

# 1. Ages as numbers
ages <- as.numeric(ages_text)

# 2. How many ages couldn't be converted?
n_unreadable <- sum(is.na(ages))

# 3. Consent as TRUE/FALSE
consent <- as.logical(consent_text)

# 4. How many consented?
n_consented <- sum(consent)
