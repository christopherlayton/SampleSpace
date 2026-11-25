# penguins is already loaded.

# 1. How many body masses are missing?
n_missing_mass <- sum(is.na(penguins$body_mass_g))

# 2. Mean body mass (g)
mean_mass <- mean(penguins$body_mass_g, na.rm = TRUE)

# 3. Add body_mass_kg
penguins$body_mass_kg <- penguins$body_mass_g / 1000
