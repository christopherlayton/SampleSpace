truth <- utils::read.csv("astronauts.csv")
m <- get_object("missions")
expect_true(is.data.frame(m) && "days" %in% names(m) && isTRUE(all.equal(m$days, truth$hours_mission / 24)),
            label = "`missions$days` is hours / 24",
            message = "Inside `mutate()`: `days = hours_mission / 24`.")
expect_true(is.data.frame(m) && "age_at_mission" %in% names(m) &&
              isTRUE(all.equal(m$age_at_mission, truth$year_of_mission - truth$year_of_birth)),
            label = "`missions$age_at_mission` is the year of mission minus year of birth",
            message = "Add `age_at_mission = year_of_mission - year_of_birth` to the same `mutate()`.")
l <- get_object("longest")
top <- sort(truth$hours_mission / 24, decreasing = TRUE)[1:5]
expect_true(is.data.frame(l) && identical(names(l), c("name", "year_of_mission", "days")),
            label = "`longest` has name, year_of_mission and days",
            message = "Select the three columns: `select(name, year_of_mission, days)`.")
expect_true(is.data.frame(l) && nrow(l) == 5 && isTRUE(all.equal(l$days, top)),
            label = "`longest` holds the five longest missions, longest first",
            message = "Sort with `arrange(desc(days))`, then keep five rows with `slice_head(n = 5)`.")
expect_object("oldest_age", max(truth$year_of_mission - truth$year_of_birth))
