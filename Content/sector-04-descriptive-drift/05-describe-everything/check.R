truth <- utils::read.csv("wellbeing_survey.csv")
vars <- c("age", "anxiety_pre", "anxiety_post", "satisfaction")
want <- psych::describe(truth[, vars])
d <- get_object("desc")
expect_called("describe")
expect_true(inherits(d, "psych") && nrow(d) == 4 && identical(rownames(d), vars) &&
              isTRUE(all.equal(d$mean, want$mean)),
            label = "`desc` describes the four variables",
            message = "Describe the four columns in this order: `describe(survey[, c(\"age\", \"anxiety_pre\", \"anxiety_post\", \"satisfaction\")])`.")
expect_object("sat_median", median(truth$satisfaction, na.rm = TRUE))
expect_object("most_skewed", vars[which.max(abs(want$skew))],
              message = "Compare the *size* of each skew: `which.max(abs(desc$skew))`. A big negative skew counts too.")
