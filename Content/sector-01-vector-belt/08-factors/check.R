expect_class("condition_f", "factor", message = "Make `condition_f` with `factor(condition, levels = ...)`.")
f <- get_object("condition_f")
expect_true(identical(levels(f), c("control", "waitlist", "treatment")),
            label = "Levels are control, waitlist, treatment",
            message = paste("Set the order with `levels = c(\"control\", \"waitlist\", \"treatment\")`.",
                            "Right now they are:", paste(levels(f), collapse = ", ")))
expect_true(identical(as.character(f), get_object("condition")),
            label = "`condition_f` has the same values as `condition`",
            message = "Check the spelling of each level; a misspelt level turns values into NA.")
expect_object("n_conditions", 3)
expect_class("condition_counts", "table", message = "Use `table(condition_f)` for the counts.")
counts <- get_object("condition_counts")
expect_true(identical(as.vector(counts), c(3L, 1L, 3L)) && identical(names(counts), c("control", "waitlist", "treatment")),
            label = "Counts are 3 control, 1 waitlist, 3 treatment",
            message = "Make the table from `condition_f` (the factor), so it follows your level order.")
