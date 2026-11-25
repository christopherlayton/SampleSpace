truth <- utils::read.csv("astronauts.csv")
b <- get_object("by_sex")
ok_shape <- is.data.frame(b) && nrow(b) == 2 && all(c("sex", "missions", "median_hours") %in% names(b))
expect_true(ok_shape, label = "`by_sex` has one row per sex with `missions` and `median_hours`",
            message = "Use `group_by(sex)` and then `summarise(missions = n(), median_hours = median(hours_mission))`.")
if (ok_shape) {
  b <- as.data.frame(b)[order(b$sex), ]
  expect_true(identical(as.integer(b$missions), as.integer(table(truth$sex))),
              label = "`missions` counts the missions for each sex",
              message = "`n()` inside `summarise()` counts the rows in each group.")
  expect_true(isTRUE(all.equal(b$median_hours, as.vector(tapply(truth$hours_mission, truth$sex, median)))),
              label = "`median_hours` is the median mission length",
              message = "Use `median(hours_mission)` inside `summarise()`.")
}
expect_called("count")
n <- get_object("nation_counts")
first <- truth[truth$mission_number == 1, ]
want <- sort(table(first$nationality), decreasing = TRUE)
expect_true(is.data.frame(n) && sum(n$n) == nrow(first),
            label = "`nation_counts` counts astronauts, not missions",
            message = paste("The counts add up to", if (is.data.frame(n) && "n" %in% names(n)) sum(n$n) else "?",
                            "but there are", nrow(first), "astronauts. Keep `mission_number == 1` before counting."))
expect_true(is.data.frame(n) && identical(as.integer(n$n), as.integer(want)),
            label = "`nation_counts` is sorted largest first",
            message = "Add `sort = TRUE` inside `count()`.")
expect_object("top_nation", names(want)[1])
