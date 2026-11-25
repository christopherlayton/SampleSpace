truth <- utils::read.csv("wellbeing_survey.csv")
vars <- c("age", "anxiety_pre", "anxiety_post")
want <- psych::describe(truth[, vars], type = 2)
d <- get_object("desc")
expect_true(inherits(d, "psych") && nrow(d) == 3 && isTRUE(all.equal(d$skew, want$skew)),
            label = "`desc` uses SPSS's skewness formula",
            message = paste("Describe age, anxiety_pre and anxiety_post with `type = 2`.",
                            "Without it, psych uses a formula that gives slightly smaller values."))
expect_object("skew_post", want["anxiety_post", "skew"],
              message = "SPSS shows -.318. Use `desc[\"anxiety_post\", \"skew\"]` from a `type = 2` describe.")
expect_object("kurt_age", want["age", "kurtosis"],
              message = "SPSS shows 1.427. Use `desc[\"age\", \"kurtosis\"]` from a `type = 2` describe.")
expect_object("n_listwise", sum(complete.cases(truth[, vars])),
              message = "Count rows complete on all three: `sum(complete.cases(survey[, vars]))`.")
