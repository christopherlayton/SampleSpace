rts <- c(512, 468, 590, 433, 615, 507)

expect_object("reaction_times", rts,
              message = "`reaction_times` has changed. Use Reset to get the starter data back.")
expect_object("avg_rt", mean(rts))
expect_called("mean")
expect_object("avg_rt_rounded", round(mean(rts), 2),
              message = "`avg_rt_rounded` should be `avg_rt` rounded to 2 decimal places (520.83).")
expect_true(grepl("digits\\s*=", learner_code()),
            label = "Names the `digits` argument",
            message = "Write the argument name: `round(avg_rt, digits = 2)`.")
expect_object("fastest", min(rts))
expect_called("min", message = paste("Use `min()` rather than typing the number, so your code",
                                     "still works when the data change."))
