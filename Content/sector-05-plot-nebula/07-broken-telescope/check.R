expect_no_error(message = "R still stops with an error. Fix the first one it reports, then run again.")
expect_ggplot("p_hist", "histogram", c(x = "hours_mission"))
p <- get_object("p_hist")
hist_layer <- if (inherits(p, "ggplot")) Filter(function(l) .gg_has_geom(l, "histogram"), p$layers) else list()
mapped_fill <- inherits(p, "ggplot") && (!is.null(p$mapping$fill) ||
                 any(vapply(hist_layer, function(l) !is.null(l$mapping$fill), TRUE)))
expect_true(length(hist_layer) > 0 && !mapped_fill && identical(hist_layer[[1]]$aes_params$fill, "steelblue"),
            label = "Every bar is steel blue (set, not mapped)",
            message = "Take `fill = \"steelblue\"` out of `aes()` and put it in the geom: `geom_histogram(bins = 30, fill = \"steelblue\")`.")
expect_true(identical(gg_label(p, "x"), "Mission length (hours)") && identical(gg_label(p, "y"), "Missions"),
            label = "`p_hist` has its axis labels",
            message = "The `labs()` layer got lost. End the line before it with `+`, so it's added to the plot.")
expect_ggplot("p_sex", "bar", c(x = "sex"),
              message = "Join the layer with `+`, not `|>`: `ggplot(astronauts, aes(x = sex)) + geom_bar()`.")
expect_plot(2)
