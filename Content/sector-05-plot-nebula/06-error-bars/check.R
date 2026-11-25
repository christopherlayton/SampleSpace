truth <- utils::read.csv("wellbeing_survey.csv")
groups <- sort(unique(truth$group))
post <- split(truth$anxiety_post, truth$group)[groups]
n <- vapply(post, function(x) sum(!is.na(x)), 1)
m <- vapply(post, mean, 1, na.rm = TRUE)
se <- vapply(post, sd, 1, na.rm = TRUE) / sqrt(n)
s <- get_object("post_summary")
ok <- is.data.frame(s) && nrow(s) == 2 && all(c("group", "n", "mean_post", "se") %in% names(s))
expect_true(ok, label = "`post_summary` has `n`, `mean_post` and `se` for each group",
            message = "`summarise(n = ..., mean_post = ..., se = ...)` after `group_by(group)`.")
if (ok) {
  s <- as.data.frame(s)[order(s$group), ]
  expect_true(isTRUE(all.equal(as.numeric(s$n), as.numeric(n))),
              label = "`n` counts the students with a post-test score",
              message = "Count non-missing values: `n = sum(!is.na(anxiety_post))`. `n()` would count the missing ones too.")
  expect_true(isTRUE(all.equal(as.numeric(s$mean_post), as.numeric(m))),
              label = "`mean_post` is each group's mean",
              message = "`mean(anxiety_post, na.rm = TRUE)`.")
  expect_true(isTRUE(all.equal(as.numeric(s$se), as.numeric(se))),
              label = "`se` is SD / √n",
              message = "`se = sd(anxiety_post, na.rm = TRUE) / sqrt(n)`.")
}
expect_ggplot("p_means", "col", c(x = "group", y = "mean_post"))
expect_ggplot("p_means", "errorbar", c(ymin = "se", ymax = "se"),
              label = "`p_means` has ±1 SE error bars",
              message = "Add `geom_errorbar(aes(ymin = mean_post - se, ymax = mean_post + se), width = 0.2)`.")
expect_plot()
