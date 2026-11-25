expect_called("str", message = "Run `str(penguins)` to see the structure.")
expect_called("summary", message = "Run `summary(penguins)` to see every variable summarised.")
expect_object("n_penguins", 344)
expect_object("n_vars", 8)
expect_object("var_names", names(palmerpenguins::penguins),
              message = "Use `names(penguins)` to get all eight variable names.")
expect_object("n_missing_mass", 2,
              message = "Look under `body_mass_g` in the `summary()` output for the `NA's` count.")
