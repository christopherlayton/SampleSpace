truth <- utils::read.csv("wellbeing_survey.csv")
expect_no_error(message = "R still stops with an error. Fix the first one it reports, then run again.")
expect_true(is.data.frame(get_object("survey")) && nrow(get_object("survey")) == 40,
            label = "`survey` is imported",
            message = "`read_csv()` comes from readr. Load it with `library(readr)` before using it.")
expect_true(is.data.frame(get_object("mindful")) && nrow(get_object("mindful")) == 20,
            label = "`mindful` holds the 20 Mindfulness students",
            message = "Compare with `==`, not `=`: `survey$group == \"Mindfulness\"`.")
expect_true(is.data.frame(get_object("control")) && nrow(get_object("control")) == 20,
            label = "`control` holds the 20 Control students",
            message = "`control` has no rows. Check the spelling: `unique(survey$group)` shows \"Control\" with a capital C.")
expect_object("mean_mindful", mean(truth$anxiety_post[truth$group == "Mindfulness"], na.rm = TRUE),
              message = paste("`mindful$Anxiety_post` is NULL: there is no such column. Run `names(survey)`;",
                              "R names are case-sensitive."))
expect_object("mean_control", mean(truth$anxiety_post[truth$group == "Control"], na.rm = TRUE),
              message = "One Control student missed the post-test, so the mean needs `na.rm = TRUE`.")
