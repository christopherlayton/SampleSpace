truth <- utils::read.csv("astronauts.csv")
first <- truth[truth$mission_number == 1, ]
fd <- floor(first$year_of_mission / 10) * 10
f <- get_object("first_flights")
expect_true(is.data.frame(f) && nrow(f) == nrow(first) && isTRUE(all.equal(as.numeric(f$decade), fd)),
            label = "`first_flights` has one row per astronaut, with `decade`",
            message = "Filter `mission_number == 1`, then `mutate(decade = floor(year_of_mission / 10) * 10)`.")
expect_ggplot("p_count", "bar", c(x = "decade", fill = "sex"))
expect_ggplot("p_share", "bar", c(x = "decade", fill = "sex"))
ps <- get_object("p_share")
bar <- if (inherits(ps, "ggplot")) Filter(function(l) inherits(l$geom, "GeomBar"), ps$layers) else list()
expect_true(length(bar) > 0 && inherits(bar[[1]]$position, "PositionFill"),
            label = "`p_share` shows proportions",
            message = "Stretch each bar to 100% with `geom_bar(position = \"fill\")`.")
w <- get_object("women_by_decade")
ok <- is.data.frame(w) && all(c("decade", "flyers", "women") %in% names(w)) && nrow(w) == length(unique(fd))
expect_true(ok && identical(as.integer(w$flyers[order(w$decade)]), as.integer(table(fd))) &&
              identical(as.integer(w$women[order(w$decade)]), as.integer(tapply(first$sex == "female", fd, sum))),
            label = "`women_by_decade` counts flyers and women per decade",
            message = "`group_by(decade) |> summarise(flyers = n(), women = sum(sex == \"female\"))` on `first_flights`.")
expect_plot(2, message = "Draw both plots: `p_count` and `p_share`.")
