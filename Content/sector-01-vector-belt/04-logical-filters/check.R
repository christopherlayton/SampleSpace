s <- c(55, 72, 64, 89, 47, 91, 68, 76)
expect_object("scores", s, message = "`scores` has changed. Use Reset to get the starter data back.")
expect_class("passed", "logical",
             message = "`passed` should be TRUE/FALSE values: `passed <- scores >= 60`.")
expect_object("passed", s >= 60,
              message = "Check the pass mark: 60 itself is a pass, so use `>=`.")
expect_object("n_passed", 6)
expect_called("sum")
expect_object("prop_passed", 0.75)
expect_object("high_scores", c(89, 91))
expect_true(grepl("scores\\s*\\[", learner_code()),
            label = "Filters `scores` with a condition in brackets",
            message = "Use the condition as the index: `scores[scores >= 80]`.")
