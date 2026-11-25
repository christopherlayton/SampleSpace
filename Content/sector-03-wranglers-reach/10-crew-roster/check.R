truth <- utils::read.csv("astronauts.csv")
ids <- sort(unique(truth$number))
eva <- tapply(truth$eva_hrs_mission, truth$number, sum)[as.character(ids)]
hours <- tapply(truth$hours_mission, truth$number, sum)[as.character(ids)]
cl <- get_object("clean")
expect_true(is.data.frame(cl) && !any(c("Hungry", "Malysia", "Netherland") %in% cl$nationality) &&
              all(c("Hungary", "Malaysia", "Netherlands") %in% cl$nationality),
            label = "`clean` has the nationality typos fixed",
            message = "Fix Hungry, Malysia and Netherland with `case_when()` inside `mutate()`, as in Typo Patrol.")
r <- get_object("roster")
cols <- c("number", "name", "sex", "nationality", "missions", "total_hours", "eva_hours")
ok <- is.data.frame(r) && all(cols %in% names(r))
expect_true(ok, label = "`roster` has the seven columns from the SPSS dialog",
            message = paste("`summarise()` needs `name`, `sex` and `nationality` (with `first()`),",
                            "`missions = n()`, `total_hours` and `eva_hours` (with `sum()`)."))
if (ok) {
  r <- as.data.frame(r)[order(r$number), ]
  expect_true(nrow(r) == length(ids),
              label = "`roster` has one row per astronaut ID (564)",
              message = "Group by the ID only: `group_by(number)`. Grouping by name as well splits ID 385 in two.")
  if (nrow(r) == length(ids)) {
    expect_true(identical(as.integer(r$missions), as.integer(table(truth$number)[as.character(ids)])) &&
                  isTRUE(all.equal(as.numeric(r$total_hours), as.numeric(hours))) &&
                  isTRUE(all.equal(as.numeric(r$eva_hours), as.numeric(eva))),
                label = "`missions`, `total_hours` and `eva_hours` match SPSS",
                message = "`missions = n()`, `total_hours = sum(hours_mission)`, `eva_hours = sum(eva_hrs_mission)`.")
    expect_true("Hungary" %in% r$nationality, label = "`roster` uses the cleaned nationalities",
                message = "Build `roster` from `clean`, not from `astronauts`.")
  }
}
expect_object("n_spacewalkers", sum(eva > 0))
expect_object("pct_spacewalkers", round(100 * sum(eva > 0) / length(ids), 1),
              message = "Divide by the number of astronauts (`nrow(roster)`), multiply by 100 and `round(..., 1)`.")
