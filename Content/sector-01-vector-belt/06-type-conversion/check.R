expect_object("ages", c(21, 34, 19, 42, NA, 28),
              message = "`ages` should be `as.numeric(ages_text)`: five numbers and one NA.")
expect_class("ages", "numeric")
expect_object("n_unreadable", 1)
expect_called("is.na", message = "Count the missing values with `sum(is.na(ages))`.")
expect_object("consent", c(TRUE, TRUE, FALSE, TRUE, TRUE, FALSE))
expect_class("consent", "logical", message = "Use `as.logical(consent_text)` so `consent` is TRUE/FALSE, not text.")
expect_object("n_consented", 4)
