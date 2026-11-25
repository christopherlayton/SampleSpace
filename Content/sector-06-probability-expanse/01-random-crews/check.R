set.seed(2026)
want_ids <- sample(1:564, size = 10)
ids <- get_object("crew_ids")
expect_true(is.numeric(ids) && length(ids) == 10 && !anyDuplicated(ids) && all(ids %in% 1:564),
            label = "`crew_ids` is 10 different IDs from 1 to 564",
            message = "Use `sample(1:564, size = 10)`. Without `replace = TRUE`, no ID can be picked twice.")
expect_called("set.seed")
expect_true(isTRUE(all.equal(as.numeric(ids), as.numeric(want_ids))),
            label = "The crew comes from seed 2026",
            message = "Put `set.seed(2026)` on the line just before `sample(1:564, size = 10)`, so the draw can be reproduced.")
r <- get_object("rolls")
ok_rolls <- is.numeric(r) && length(r) == 600 && all(r %in% 1:6) && length(unique(r)) == 6
expect_true(ok_rolls, label = "`rolls` holds 600 die rolls",
            message = "`sample(1:6, size = 600, replace = TRUE)`. A die can repeat a face, so it needs `replace = TRUE`.")
expect_true(ok_rolls && isTRUE(all.equal(get_object("prop_six"), mean(r == 6))),
            label = "`prop_six` is the proportion of sixes",
            message = "`mean(rolls == 6)` turns TRUE/FALSE into the proportion TRUE.")
expect_called("table")
