s0 <- utils::read.csv("sleep_morale.csv")
ct0 <- cor.test(s0$sleep_hours, s0$morale_score)
expect_ggplot("p", geom = "point", aes = c(x = "sleep_hours", y = "morale_score"),
              message = "`ggplot(sleep, aes(x = sleep_hours, y = morale_score)) + geom_point()`.")
pr <- get_object("pearson")
expect_true(inherits(pr, "htest") && grepl("Pearson", pr$method) && isTRUE(all.equal(unname(pr$estimate), unname(ct0$estimate))),
            label = "`pearson` is the Pearson test of sleep and morale",
            message = "`cor.test(sleep$sleep_hours, sleep$morale_score)`.")
expect_object("r", unname(ct0$estimate), tolerance = 1e-10, check_attributes = FALSE, message = "`unname(pearson$estimate)`.")
expect_object("df", unname(ct0$parameter), tolerance = 1e-10, check_attributes = FALSE, message = "`pearson$parameter`: n − 2 = 44.")
expect_object("ci", ct0$conf.int, tolerance = 1e-10, check_attributes = FALSE, message = "`pearson$conf.int`.")
expect_object("r_squared", unname(ct0$estimate)^2, tolerance = 1e-10, check_attributes = FALSE, message = "`r^2`.")
sp0 <- cor.test(s0$sleep_hours, s0$morale_score, method = "spearman", exact = FALSE)
sp <- get_object("spearman")
expect_true(inherits(sp, "htest") && grepl("Spearman", sp$method) && isTRUE(all.equal(sp$p.value, sp0$p.value)),
            label = "`spearman` is Spearman's test with the approximate p-value",
            message = "`cor.test(sleep$sleep_hours, sleep$morale_score, method = \"spearman\", exact = FALSE)`.")
