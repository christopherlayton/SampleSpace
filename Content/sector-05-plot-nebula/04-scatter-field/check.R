expect_ggplot("p_scatter", "point", c(x = "year_of_mission", y = "age_at_mission"))
p <- get_object("p_scatter")
alpha_of <- function(p) {
  if (!inherits(p, "ggplot")) return(NULL)
  for (l in p$layers) if (inherits(l$geom, "GeomPoint")) return(l$aes_params$alpha)
  NULL
}
expect_true(identical(alpha_of(p), 0.3),
            label = "`p_scatter`'s points are 30% opaque",
            message = "Set transparency outside `aes()`: `geom_point(alpha = 0.3)`.")
expect_ggplot("p_trend", "point", c(colour = "sex"),
              message = "Map colour to sex inside `aes()`: `aes(x = ..., y = ..., colour = sex)`.")
pt <- get_object("p_trend")
smooth <- if (inherits(pt, "ggplot")) Filter(function(l) inherits(l$geom, "GeomSmooth"), pt$layers) else list()
expect_true(length(smooth) == 1 && identical(smooth[[1]]$stat_params$method, "lm"),
            label = "`p_trend` has a straight trend line",
            message = "Add `+ geom_smooth(method = \"lm\")`. Without `method = \"lm\"` you get a wiggly smoother instead of a line.")
expect_plot(2, message = "Draw both plots: `p_scatter` and `p_trend`, each on a line of its own.")
