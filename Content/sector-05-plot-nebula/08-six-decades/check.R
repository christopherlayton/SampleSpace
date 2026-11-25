truth <- utils::read.csv("astronauts.csv")
decade <- floor(truth$year_of_mission / 10) * 10
want <- tapply(truth$hours_mission, decade, median)
d <- get_object("decade_medians")
expect_true(is.data.frame(d) && nrow(d) == length(want) && "median_hours" %in% names(d) &&
              isTRUE(all.equal(as.numeric(d$median_hours[order(d$decade)]), as.numeric(want))),
            label = "`decade_medians` has each decade's median",
            message = "`missions |> group_by(decade) |> summarise(median_hours = median(hours_mission))`.")
expect_ggplot("p_final", "point", c(x = "decade", y = "median_hours"))
expect_ggplot("p_final", "line", c(x = "decade", y = "median_hours"),
              message = "Join the points: add `+ geom_line()` as well as `geom_point()`.")
p <- get_object("p_final")
expect_true(identical(gg_label(p, "x"), "Decade") && identical(gg_label(p, "y"), "Median mission length (hours)"),
            label = "The axes are titled in words",
            message = "`labs(x = \"Decade\", y = \"Median mission length (hours)\")`.")
expect_called("theme_classic", message = "Finish with `+ theme_classic()` for an APA-style look.")
expect_true(file.exists("six_decades.png"),
            label = "The figure is saved as six_decades.png",
            message = "`ggsave(\"six_decades.png\", p_final, width = 6, height = 4)`.")
expect_plot()
