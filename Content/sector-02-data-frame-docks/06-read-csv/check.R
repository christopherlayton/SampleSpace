truth <- utils::read.csv("wellbeing_survey.csv")
expect_called("read_csv", message = "Import the file with `read_csv()` from the readr package.")
expect_true(is.data.frame(get_object("survey")) && nrow(get_object("survey")) == 40 &&
              ncol(get_object("survey")) == 8,
            label = "`survey` holds the whole file (40 rows, 8 columns)",
            message = "Import it with `survey <- read_csv(\"wellbeing_survey.csv\")`.")
expect_object("n_students", 40)
counts <- get_object("group_counts")
expect_true(inherits(counts, "table") && identical(as.vector(counts), c(20L, 20L)),
            label = "`group_counts` shows 20 students per group",
            message = "Use `table(survey$group)`.")
expect_object("mean_post", mean(truth$anxiety_post, na.rm = TRUE),
              message = "Three students missed the post-test, so add `na.rm = TRUE`.")
