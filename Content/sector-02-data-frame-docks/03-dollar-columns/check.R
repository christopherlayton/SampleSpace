mass <- palmerpenguins::penguins$body_mass_g
expect_object("n_missing_mass", 2)
expect_called("is.na", message = "Calculate it: `sum(is.na(penguins$body_mass_g))`.")
expect_object("mean_mass", mean(mass, na.rm = TRUE),
              message = "Use `mean(penguins$body_mass_g, na.rm = TRUE)`.")
p <- get_object("penguins")
expect_true("body_mass_kg" %in% names(p), label = "`penguins` has a `body_mass_kg` column",
            message = "Add it with `penguins$body_mass_kg <- ...`.")
expect_true(isTRUE(all.equal(p$body_mass_kg, mass / 1000)),
            label = "`body_mass_kg` is the mass in kilograms",
            message = "Kilograms are grams divided by 1000: `penguins$body_mass_g / 1000`.")
expect_true(is.data.frame(p) && nrow(p) == 344, label = "`penguins` still has all 344 rows",
            message = "Something replaced `penguins`. Use Reset and add the column with `$`.")
