rt <- c(512, 468, 590, 433, 615, 507)
expect_object("reaction", rt, message = "`reaction` has changed. Use Reset to get the starter data back.")
expect_object("first_trial", 512)
expect_object("last_trial", 507)
expect_true(grepl("reaction\\[\\s*length\\(\\s*reaction\\s*\\)\\s*\\]", learner_code()),
            label = "Finds the last trial with `length()`",
            message = "Write `reaction[length(reaction)]` so it works for any number of trials.")
expect_object("real_trials", rt[-1])
expect_true(grepl("\\[\\s*-", learner_code()),
            label = "Drops the practice trial with a negative index",
            message = "A minus sign inside the brackets drops a position: `reaction[-1]`.")
expect_object("middle_trials", rt[2:5])
