code <- learner_code()
expect_true(grepl("\\?\\s*seq|help\\(\\s*\"?seq|args\\(\\s*seq", code),
            label = "Looks up the help for `seq()`",
            message = "Add a line with `?seq` or `args(seq)` to look it up.")
expect_object("checkpoints", seq(0, 100, by = 25))
expect_called("seq")
expect_true(grepl("by\\s*=", code) && grepl("from\\s*=", code) && grepl("to\\s*=", code),
            label = "Names the `from`, `to` and `by` arguments",
            message = "Write the argument names: `seq(from = 0, to = 100, by = 25)`.")
expect_object("likert_points", 1:7)
expect_true(grepl("likert_points\\s*(<-|=)\\s*1\\s*:\\s*7", code),
            label = "Uses the `:` shortcut for `likert_points`",
            message = "Try the colon shortcut: `likert_points <- 1:7`.")
