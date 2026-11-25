truth <- utils::read.csv("crew_morale.csv")
items <- cbind(truth$m1, 6 - truth$m2, truth$m3, truth$m4, 6 - truth$m5, truth$m6)
score <- rowMeans(items, na.rm = TRUE)
expect_object("r_before", cor(truth$m1, truth$m2, use = "complete.obs"),
              message = "Use `cor(morale$m1, morale$m2, use = \"complete.obs\")`.")
m <- get_object("morale")
expect_true(is.data.frame(m) && isTRUE(all.equal(m$m2_r, 6 - truth$m2)) && isTRUE(all.equal(m$m5_r, 6 - truth$m5)),
            label = "`m2_r` and `m5_r` are reverse-scored",
            message = "On a 1–5 scale, reversed = 6 − score: `mutate(m2_r = 6 - m2, m5_r = 6 - m5)`.")
expect_object("r_after", cor(truth$m1, 6 - truth$m2, use = "complete.obs"),
              message = "Correlate `m1` with the reversed item, `m2_r`. It should now be positive.")
expect_true(is.data.frame(m) && isTRUE(all.equal(m$morale_score, score)),
            label = "`morale_score` averages the six items, reversed where needed",
            message = paste("Average m1, m2_r, m3, m4, m5_r and m6 with `rowMeans(..., na.rm = TRUE)`.",
                            "If a few scores are NA, you left out `na.rm = TRUE`; if they're too low, you used m2 or m5 unreversed."))
expect_object("mean_morale", mean(score))
