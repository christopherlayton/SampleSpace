sleep <- c(7, 6.5, NA, 8, 5.5, NA, 7.5, 6)
expect_object("sleep_hours", sleep, message = "`sleep_hours` has changed. Use Reset to get the starter data back.")
expect_object("n_missing", 2)
expect_object("n_valid", 6)
expect_object("mean_sleep", mean(sleep, na.rm = TRUE),
              message = "`mean_sleep` should be 6.75: `mean(sleep_hours, na.rm = TRUE)`.")
expect_true(grepl("na\\.rm\\s*=\\s*(TRUE|T)\\b", learner_code()),
            label = "Uses `na.rm = TRUE`",
            message = "Let `mean()` skip the missing values with `na.rm = TRUE` rather than typing the numbers again.")
