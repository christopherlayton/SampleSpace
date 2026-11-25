truth <- utils::read.csv("astronauts.csv")
f <- truth[truth$mission_number == 1, ]
age <- f$year_of_mission - f$year_of_birth
expect_no_error(message = "R still stops with an error. Fix the first one it reports, then run again.")
b <- get_object("big_draw")
expect_true(is.numeric(b) && length(b) == 1000 && all(b %in% age),
            label = "`big_draw` is 1,000 ages from the log",
            message = "Drawing 1,000 from 564 needs `replace = TRUE`.")
m <- get_object("crew_means")
ok <- is.numeric(m) && length(m) == 2000
expect_true(ok && length(unique(m)) > 10,
            label = "`crew_means` holds 2,000 different random crews",
            message = paste("All the crews are the same crew. `set.seed()` inside `replicate()` restarts the",
                            "generator before every draw: delete it (the seed is already set once for this level)."))
expect_true(ok && abs(sd(m) - sd(age) / sqrt(10)) < 0.25,
            label = "The crews are random crews of 10",
            message = "Each repeat should be `mean(sample(age, size = 10, replace = TRUE))`.")
expect_true(ok && isTRUE(all.equal(get_object("se_sim"), sd(m))),
            label = "`se_sim` is the SD of the crew means",
            message = "`se_sim <- sd(crew_means)`.")
expect_object("se_formula", sd(age) / sqrt(10),
              message = "The standard error divides by the *square root* of n: `sd(age) / sqrt(10)`.")
