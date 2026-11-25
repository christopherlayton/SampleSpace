pop <- utils::read.csv("astronauts.csv")$hours_mission
one <- get_object("one_crew")
expect_true(is.numeric(one) && length(one) == 30 && all(one %in% pop),
            label = "`one_crew` is 30 missions from the log",
            message = "Draw it with `sample(hours, size = 30, replace = TRUE)`.")
means <- get_object("crew_means")
ok_means <- is.numeric(means) && length(means) == 1000
expect_true(ok_means, label = "`crew_means` holds 1,000 crew averages",
            message = "`replicate(1000, mean(sample(hours, size = 30, replace = TRUE)))` keeps one mean per crew.")
expect_true(ok_means && abs(mean(means) - mean(pop)) < 60 && sd(means) > 220 && sd(means) < 420,
            label = "The averages come from crews of 30",
            message = paste("The spread of `crew_means` doesn't fit crews of 30 missions. Check `size = 30`",
                            "and `replace = TRUE` inside `sample()`, and that you take the `mean()` of each crew."))
expect_object("se_sim", if (ok_means) sd(means) else NA_real_,
              message = "The simulated standard error is the SD of the crew means: `sd(crew_means)`.")
expect_object("se_formula", sd(pop) / sqrt(30),
              message = "The formula is σ / √n: `sd(hours) / sqrt(30)`.")
expect_called("replicate")
expect_plot(message = "Finish with `hist(crew_means)` to see the bell.")
