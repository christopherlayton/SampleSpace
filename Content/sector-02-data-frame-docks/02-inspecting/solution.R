# penguins is already loaded.

# 1. Look at it
str(penguins)
summary(penguins)

# 2. How many penguins and variables?
n_penguins <- nrow(penguins)
n_vars <- ncol(penguins)

# 3. The variable names
var_names <- names(penguins)

# 4. Penguins with no body mass (read it off summary())
n_missing_mass <- 2
