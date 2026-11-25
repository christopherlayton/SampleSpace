s <- data.frame(
  id = sprintf("P%02d", 1:12),
  condition = rep(c("control", "treatment"), times = 6),
  age = c(22, 31, 19, 27, 24, 35, 29, 21, 26, 33, 20, 28),
  score = c(54, 67, 49, 72, 58, 75, 61, 70, 52, 69, 47, 74)
)
same_df <- function(a, b) is.data.frame(a) && identical(names(a), names(b)) &&
  isTRUE(all.equal(a, b, check.attributes = FALSE))
expect_true(same_df(get_object("row_three"), s[3, ]), label = "`row_three` is row 3",
            message = "Rows come before the comma: `study[3, ]`.")
expect_object("all_scores", s$score, message = "Columns come after the comma: `study[, \"score\"]`.")
expect_true(same_df(get_object("treatment_only"), s[s$condition == "treatment", ]),
            label = "`treatment_only` has the 6 treatment rows",
            message = "Use a condition before the comma: `study[study$condition == \"treatment\", ]`.")
expect_true(same_df(get_object("older_scores"), s[s$age >= 25, c("id", "score")]),
            label = "`older_scores` has id and score for ages 25+",
            message = "Rows: `study$age >= 25`. Columns: `c(\"id\", \"score\")`.")
