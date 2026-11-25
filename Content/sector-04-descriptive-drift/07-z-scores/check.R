truth <- utils::read.csv("astronauts.csv")
h <- truth$hours_mission
z <- (h - mean(h)) / sd(h)
zz <- get_object("z_hours")
expect_true(is.numeric(zz) && is.null(dim(zz)) && length(zz) == length(h) && isTRUE(all.equal(as.numeric(zz), z)),
            label = "`z_hours` holds every mission's z-score",
            message = paste("Use `(hours - mean(hours)) / sd(hours)`.",
                            "If you used `scale()`, wrap it in `as.numeric()` to get a plain vector."))
expect_object("n_extreme", sum(abs(z) > 3),
              message = "Count both tails: `sum(abs(z_hours) > 3)`.")
expect_object("max_z", max(z))
expect_object("prop_below", mean(z < 0),
              message = "`mean(z_hours < 0)` gives the proportion of TRUEs.")
