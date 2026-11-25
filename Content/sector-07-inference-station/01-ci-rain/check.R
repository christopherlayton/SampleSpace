ages <- get_object("ages")
expect_true(is.numeric(ages) && length(ages) == 25,
            label = "`ages` holds 25 ages", message = "Keep the first line: `ages <- rnorm(25, mean = 40, sd = 5)`.")
if (is.numeric(ages) && length(ages) == 25) {
  expect_object("ci95", as.numeric(t.test(ages)$conf.int),
                message = "Use `t.test(ages)$conf.int`.")
  expect_object("ci99", as.numeric(t.test(ages, conf.level = 0.99)$conf.int),
                message = "Add `conf.level = 0.99` inside `t.test()`.")
}
cap <- get_object("captured")
expect_true(is.logical(cap) && length(cap) == 1000,
            label = "`captured` holds 1,000 TRUE/FALSE results",
            message = paste("Inside `replicate()`, finish with a comparison such as `ci[1] <= 40 & 40 <= ci[2]`,",
                            "so each repeat returns TRUE or FALSE."))
expect_true(is.logical(cap) && isTRUE(all.equal(get_object("coverage"), mean(cap))),
            label = "`coverage` is the proportion captured",
            message = "`coverage <- mean(captured)`.")
expect_true(is.logical(cap) && mean(cap) > 0.92 && mean(cap) < 0.98,
            label = "Coverage is close to 95%",
            message = "About 95% of 95% intervals should capture 40. Check that each CI uses its own sample `x`.")
