truth <- utils::read.csv("astronauts.csv")
want_recent <- truth[truth$year_of_mission >= 2010, ]
expect_called("filter", message = "Keep rows with dplyr's `filter()`.")
r <- get_object("recent")
expect_true(is.data.frame(r) && identical(names(r), c("name", "nationality", "year_of_mission", "hours_mission")),
            label = "`recent` has the four columns, in order",
            message = "Add `|> select(name, nationality, year_of_mission, hours_mission)` after the filter.")
expect_true(is.data.frame(r) && nrow(r) == nrow(want_recent) && all(r$year_of_mission >= 2010),
            label = "`recent` holds the missions from 2010 on",
            message = "Keep missions with `year_of_mission >= 2010` (from 2010 on includes 2010 itself).")
expect_object("n_recent", nrow(want_recent))
lw <- get_object("long_women")
want_lw <- truth[truth$sex == "female" & truth$hours_mission > 4000, ]
expect_true(is.data.frame(lw) && nrow(lw) == nrow(want_lw) && all(lw$sex == "female"),
            label = "`long_women` holds women's missions over 4,000 hours",
            message = "Both conditions in one filter: `filter(sex == \"female\", hours_mission > 4000)`.")
