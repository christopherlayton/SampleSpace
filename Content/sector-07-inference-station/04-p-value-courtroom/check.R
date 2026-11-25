se <- 6.5 * sqrt(2 / 19)
t_obs <- 1.8 / se
df <- 36
expect_object("se", se, message = "SE = SD × √(2 / n): `sd_pooled * sqrt(2 / n)`.")
expect_object("t_obs", t_obs, message = "t is the difference over its SE: `diff / se`.")
expect_object("df", df, message = "Two groups of n: `2 * n - 2`.")
expect_object("p_two", 2 * pt(-abs(t_obs), df),
              message = "Two-sided: both tails, `2 * pt(-abs(t_obs), df)`.")
expect_object("p_one", pt(t_obs, df, lower.tail = FALSE),
              message = "One-sided (greater): the upper tail only, `pt(t_obs, df, lower.tail = FALSE)`.")
s <- get_object("sim_t")
expect_true(is.numeric(s) && length(s) == 2000,
            label = "`sim_t` holds 2,000 simulated t statistics",
            message = "Each repeat should end with `t.test(a, b, var.equal = TRUE)$statistic`.")
expect_true(is.numeric(s) && length(s) == 2000 &&
              isTRUE(all.equal(get_object("sim_p"), mean(abs(s) >= abs(t_obs)))),
            label = "`sim_p` is the share at least as extreme",
            message = "Compare sizes, ignoring sign: `mean(abs(sim_t) >= abs(t_obs))`.")
expect_true(is.numeric(get_object("sim_p")) && abs(get_object("sim_p") - 2 * pt(-abs(t_obs), df)) < 0.05,
            label = "The simulation agrees with the exact p",
            message = "`sim_p` should be within a few points of `p_two`. Check the simulation draws from the same SD and n.")
