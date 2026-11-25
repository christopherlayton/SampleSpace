a <- get_object("ages")
ok <- is.numeric(a) && length(a) == 1000
expect_true(ok, label = "`ages` holds 1,000 simulated ages",
            message = "`rnorm(1000, mean = 40, sd = 5)`: how many, then the mean and SD.")
expect_true(ok && abs(mean(a) - 40) < 1 && abs(sd(a) - 5) < 0.6,
            label = "The ages come from N(40, 5)",
            message = "The simulated ages don't look like mean 40 and SD 5. Check the `mean` and `sd` arguments of `rnorm()`.")
expect_true(ok && isTRUE(all.equal(get_object("sim_over_50"), mean(a > 50))),
            label = "`sim_over_50` is the simulated proportion",
            message = "`mean(ages > 50)` gives the proportion of TRUEs.")
expect_object("exact_over_50", pnorm(50, mean = 40, sd = 5, lower.tail = FALSE),
              message = "The area above 50: `pnorm(50, mean = 40, sd = 5, lower.tail = FALSE)` (about 0.023).")
expect_true(ok && isTRUE(all.equal(get_object("sim_mean"), mean(a))) && isTRUE(all.equal(get_object("sim_sd"), sd(a))),
            label = "`sim_mean` and `sim_sd` describe the simulation",
            message = "`sim_mean <- mean(ages)` and `sim_sd <- sd(ages)`.")
expect_plot(message = "Finish with `hist(ages)`.")
