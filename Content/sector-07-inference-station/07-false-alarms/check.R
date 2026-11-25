pn <- get_object("p_null")
ok_null <- is.numeric(pn) && length(pn) == 2000 && all(pn >= 0 & pn <= 1)
expect_true(ok_null, label = "`p_null` holds 2,000 p-values",
            message = "Each repeat should end with `t.test(a, b, var.equal = TRUE)$p.value`.")
expect_true(ok_null && mean(pn < 0.05) > 0.03 && mean(pn < 0.05) < 0.07,
            label = "Those studies have no real difference",
            message = "About 5% of p-values should be below .05 when H₀ is true. Draw both groups from `rnorm(20)`.")
expect_true(ok_null && isTRUE(all.equal(get_object("type1"), mean(pn < 0.05))),
            label = "`type1` is the share of false alarms", message = "`mean(p_null < 0.05)`.")
pe <- get_object("p_effect")
exact <- power.t.test(n = 20, delta = 0.5)$power
ok_eff <- is.numeric(pe) && length(pe) == 2000 && all(pe >= 0 & pe <= 1)
expect_true(ok_eff && abs(mean(pe < 0.05) - exact) < 0.05,
            label = "`p_effect` comes from studies with d = 0.5",
            message = "Give one group a mean of 0.5 (SD 1): `rnorm(20, mean = 0.5)`, the other `rnorm(20)`, 20 per group.")
expect_true(ok_eff && isTRUE(all.equal(get_object("power_sim"), mean(pe < 0.05))) &&
              isTRUE(all.equal(get_object("type2"), 1 - mean(pe < 0.05))),
            label = "`power_sim` and `type2` are right",
            message = "`power_sim <- mean(p_effect < 0.05)` and `type2 <- 1 - power_sim`.")
expect_object("power_exact", exact, message = "`power.t.test(n = 20, delta = 0.5)$power`.")
expect_plot(message = "Finish with `hist(p_null)`: it should look flat.")
