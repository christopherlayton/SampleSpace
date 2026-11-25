truth <- utils::read.csv("astronauts.csv")
expect_ggplot("p_hours", "histogram", c(x = "hours_mission"))
p <- get_object("p_hours")
expect_true(inherits(p, "ggplot") && length(p$layers) > 0 && identical(p$layers[[1]]$stat_params$bins, 40),
            label = "`p_hours` uses 40 bins",
            message = "Set the number of bins inside the geom: `geom_histogram(bins = 40)`.")
f <- get_object("first_flights")
first <- truth[truth$mission_number == 1, ]
expect_true(is.data.frame(f) && nrow(f) == nrow(first) && isTRUE(all.equal(f$age, first$year_of_mission - first$year_of_birth)),
            label = "`first_flights` has one row per astronaut with `age`",
            message = "Filter `mission_number == 1`, then `mutate(age = year_of_mission - year_of_birth)`.")
expect_ggplot("p_age", "histogram", c(x = "age"))
p2 <- get_object("p_age")
expect_true(inherits(p2, "ggplot") && length(p2$layers) > 0 && identical(p2$layers[[1]]$stat_params$binwidth, 2),
            label = "`p_age` uses a bin width of 2",
            message = "Use `geom_histogram(binwidth = 2)`.")
expect_plot(2, message = "Draw both plots: put `p_hours` and `p_age` each on a line of its own.")
