expect_called("power.t.test")
expect_object("power_20", power.t.test(n = 20, delta = 0.5, sd = 1)$power,
              message = "`power.t.test(n = 20, delta = 0.5, sd = 1)$power`.")
n64 <- power.t.test(power = 0.80, delta = 0.5, sd = 1)$n
expect_object("n_needed", ceiling(n64),
              message = sprintf("R says n = %.2f per group. You can't recruit part of a person, so round up with `ceiling()`.", n64))
expect_object("d_30", power.t.test(n = 30, power = 0.80, sd = 1)$delta,
              message = "Give n and power, and leave out delta: `power.t.test(n = 30, power = 0.80, sd = 1)$delta`.")
expect_object("n_small", ceiling(power.t.test(power = 0.80, delta = 0.2, sd = 1)$n),
              message = "Same as step 2 with `delta = 0.2`, rounded up.")
