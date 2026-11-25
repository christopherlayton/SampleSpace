raw0 <- c(34, 41, 28, 45, 38)
expect_object("raw", raw0, message = "`raw` has changed. Use Reset to get the starter data back.")
expect_object("percent", raw0 / 50 * 100,
              message = "`percent` should be 68, 82, 56, 90, 76: divide by 50, then multiply by 100.")
expect_object("centred", raw0 - mean(raw0))
expect_called("mean", message = "Let R work out the mean with `mean(raw)` instead of typing 37.2.")
expect_true(abs(sum(get_object("centred") %||% 1)) < 1e-9,
            label = "The centred scores sum to zero",
            message = "Mean-centred scores always add up to 0. Subtract `mean(raw)` from `raw`.")
