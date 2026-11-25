truth <- utils::read.csv("astronauts.csv")
expect_object("mean_hours", mean(truth$hours_mission))
expect_object("median_hours", median(truth$hours_mission))
counts <- table(truth$total_number_of_missions[truth$mission_number == 1])
expect_object("mode_missions", as.numeric(names(counts)[which.max(counts)]),
              message = "Take the name of the biggest count, `names(counts)[which.max(counts)]`, and wrap it in `as.numeric()`.")
