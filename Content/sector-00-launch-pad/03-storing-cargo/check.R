expect_object("n_responses", 40)
expect_object("mean_satisfaction", 3.8)
expect_object("total_points", 152)

# total_points should be built from the objects, not typed in as 152.
code_lines <- strsplit(learner_code(), "\n")[[1]]
total_lines <- grep("total_points\\s*(<-|=)", code_lines, value = TRUE)
expect_true(any(grepl("n_responses", total_lines) & grepl("mean_satisfaction", total_lines)),
            label = "`total_points` is calculated from the other two objects",
            message = paste("Build `total_points` from `n_responses` and `mean_satisfaction`.",
                            "Then if the data change, your result updates too."))

expect_printed(152, label = "Prints `total_points`",
               message = "Type `total_points` on a line by itself to print it.")
