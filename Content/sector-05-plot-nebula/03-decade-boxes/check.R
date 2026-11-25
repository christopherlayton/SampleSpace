truth <- utils::read.csv("astronauts.csv")
decade <- floor(truth$year_of_mission / 10) * 10
m <- get_object("missions")
expect_true(is.data.frame(m) && isTRUE(all.equal(as.numeric(m$decade), decade)),
            label = "`missions$decade` holds the decade",
            message = "`mutate(decade = floor(year_of_mission / 10) * 10)`: 1987 → 198.7 → 198 → 1980.")
expect_ggplot("p_box", "boxplot", c(x = "decade", y = "hours_mission"))
pl <- get_object("p_log")
expect_ggplot("p_log", "boxplot", c(x = "decade", y = "hours_mission"))
expect_true(inherits(pl, "ggplot") && any(vapply(pl$scales$scales, function(s) "y" %in% s$aesthetics &&
                                                    identical(s$trans$name %||% s$transformation$name, "log-10"), TRUE)),
            label = "`p_log` has a log-10 y-axis",
            message = "Add `+ scale_y_log10()`.")
d <- get_object("decade_medians")
want <- tapply(truth$hours_mission, decade, median)
expect_true(is.data.frame(d) && nrow(d) == length(want) && "median_hours" %in% names(d) &&
              isTRUE(all.equal(as.numeric(d$median_hours[order(d$decade)]), as.numeric(want))),
            label = "`decade_medians` has each decade's median",
            message = "`group_by(decade) |> summarise(median_hours = median(hours_mission))`.")
expect_plot(2, message = "Draw both plots: `p_box` and `p_log`, each on a line of its own.")
