truth <- haven::read_sav("teaching_study.sav")
f <- get_object("teach_f")
expect_true(is.data.frame(f) && is.factor(f$method) && is.factor(f$gender) && is.numeric(f$score),
            label = "`teach_f` has factors for the labelled columns",
            message = "Convert the whole data frame: `teach_f <- as_factor(teach)`.")
expect_object("n_active", 15)
expect_object("n_no_answer", 2,
              message = "The two \"No answer\" codes arrive as NA. Count them with `sum(is.na(teach$anxiety))`.")
expect_object("mean_anxiety", mean(truth$anxiety, na.rm = TRUE),
              message = paste("Average `teach$anxiety` with `na.rm = TRUE`. If you got a number above 3.5,",
                              "the 9 codes were counted as answers."))
