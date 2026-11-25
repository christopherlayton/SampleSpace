scores <- c(12, 18, 9, 22, 15, 11, 19, 14)
expect_object("anxiety", scores,
              message = "`anxiety` should hold 12, 18, 9, 22, 15, 11, 19, 14 in that order, made with `c()`.")
expect_object("n_participants", 8)
expect_called("length")
expect_object("total_anxiety", sum(scores))
expect_object("mean_anxiety", mean(scores))
expect_called("mean", message = "Let R do the averaging with `mean(anxiety)`.")
