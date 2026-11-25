truth <- haven::read_sav("teaching_study.sav")
expect_called("read_sav", message = "Import the file with `read_sav()` from the haven package.")
expect_true(is.data.frame(get_object("teach")) && nrow(get_object("teach")) == 30,
            label = "`teach` holds the 30 students",
            message = "Import it with `teach <- read_sav(\"teaching_study.sav\")`.")
expect_object("n_students", 30)
expect_object("mean_score", mean(truth$score))
expect_called("as_factor", message = "Turn the codes into labels with `as_factor(teach$method)`.")
counts <- get_object("method_counts")
expect_true(inherits(counts, "table") && identical(names(counts), c("Lecture", "Active learning")) &&
              identical(as.vector(counts), c(15L, 15L)),
            label = "`method_counts` counts Lecture and Active learning by name",
            message = "Make the table from the labels: `table(as_factor(teach$method))`.")
