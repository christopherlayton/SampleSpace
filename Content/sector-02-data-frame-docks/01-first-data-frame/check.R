expect_class("study", "data.frame", message = "Make `study` with `data.frame(id = id, group = group, score = score)`.")
s <- get_object("study")
expect_true(identical(names(s), c("id", "group", "score")),
            label = "Columns are `id`, `group`, `score`",
            message = paste("Name the columns id, group and score, in that order. They are currently:",
                            paste(names(s), collapse = ", ")))
expect_true(is.data.frame(s) && nrow(s) == 5 && identical(s$score, c(14, 19, 11, 22, 17)),
            label = "`study` holds the five participants",
            message = "Use the three vectors from the starter code as the columns.")
expect_object("n_cases", 5)
expect_object("n_variables", 3)
expect_called("nrow")
