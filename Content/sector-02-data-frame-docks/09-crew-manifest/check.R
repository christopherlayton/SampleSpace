truth <- utils::read.csv("astronauts.csv")
a <- get_object("astronauts")
expect_true(is.data.frame(a) && nrow(a) == nrow(truth) && ncol(a) == ncol(truth),
            label = "`astronauts` holds the whole log",
            message = "Import it with `astronauts <- read_csv(\"astronauts.csv\")`.")
expect_object("n_missions", nrow(truth))
expect_object("n_astronauts", length(unique(truth$number)),
              message = paste("Count each ID once: `length(unique(astronauts$number))`.",
                              "If you got 1277, that's missions, not people."))
expect_called("unique")
f <- get_object("first_flights")
expect_true(is.data.frame(f) && nrow(f) == sum(truth$mission_number == 1) && all(f$mission_number == 1),
            label = "`first_flights` has one row per astronaut",
            message = "Keep the rows where `mission_number == 1` (note the comma: `astronauts[condition, ]`).")
counts <- get_object("sex_counts")
want <- table(truth$sex[truth$mission_number == 1])
expect_true(inherits(counts, "table") && identical(names(counts), names(want)) &&
              identical(as.vector(counts), as.vector(want)),
            label = "`sex_counts` counts people, not missions",
            message = paste("Make the table from `first_flights`. Counting `astronauts$sex` would count",
                            "missions: frequent flyers would be counted several times."))
