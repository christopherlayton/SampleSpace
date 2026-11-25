expect_class("gender_f", "factor")
g <- get_object("gender_f")
expect_true(identical(as.character(g), c("Woman", "Man", "Man", "Woman", "Non-binary", "Woman")),
            label = "`gender_f` has the labels Woman, Man, Non-binary",
            message = "Use `levels = 1:3, labels = c(\"Woman\", \"Man\", \"Non-binary\")`.")
expect_true(!is.ordered(g), label = "`gender_f` is not ordered (nominal)",
            message = "Gender categories have no order, so leave out `ordered = TRUE`.")
expect_class("education_f", "ordered", message = "Make `education_f` with `ordered = TRUE`.")
e <- get_object("education_f")
expect_true(identical(levels(e), c("HS", "BA", "MA", "PhD")),
            label = "Education levels run HS < BA < MA < PhD",
            message = "List the levels lowest to highest: `levels = c(\"HS\", \"BA\", \"MA\", \"PhD\")`.")
expect_true(identical(as.character(e), get_object("education")),
            label = "`education_f` keeps every participant's degree",
            message = "Check the spelling of the levels; a mismatch turns values into NA.")
expect_object("mean_wellbeing", mean(c(32, 41, 38, 45, 36)))
