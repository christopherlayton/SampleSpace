truth <- utils::read.csv("wellbeing_survey.csv")
s <- get_object("survey")
expect_true(is.data.frame(s) && nrow(s) == 40, label = "`survey` holds the 40 students",
            message = "Import with `survey <- read_csv(\"wellbeing_survey.csv\")`.")
expect_true(is.factor(s$group) && identical(levels(s$group), c("Control", "Mindfulness")),
            label = "`group` is a factor with Control first",
            message = "Use `factor(survey$group, levels = c(\"Control\", \"Mindfulness\"))`.")
m <- get_object("missing_per_column")
expect_true(!is.null(m) && isTRUE(all(m[c("age", "anxiety_post", "satisfaction")] == c(1, 3, 2))) &&
              sum(m) == 6,
            label = "`missing_per_column` counts NAs in each column",
            message = "Use `colSums(is.na(survey))` before adding the change column.")
expect_object("n_complete", sum(complete.cases(truth)))
expect_true(isTRUE(all.equal(s$change, truth$anxiety_post - truth$anxiety_pre)),
            label = "`survey$change` is post minus pre",
            message = "Subtract pre from post: `survey$anxiety_post - survey$anxiety_pre`.")
expect_object("mean_change", mean(truth$anxiety_post - truth$anxiety_pre, na.rm = TRUE))
