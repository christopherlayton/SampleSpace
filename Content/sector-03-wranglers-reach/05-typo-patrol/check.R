truth <- utils::read.csv("astronauts.csv")
cl <- get_object("clean")
ok <- is.data.frame(cl) && nrow(cl) == nrow(truth)
expect_true(ok, label = "`clean` keeps every mission",
            message = "Make `clean` from `astronauts` with `mutate()` only; don't filter rows away.")
if (ok) {
  fixed <- c(Hungry = "Hungary", Malysia = "Malaysia", Netherland = "Netherlands")
  for (typo in names(fixed)) {
    rows <- truth$nationality == typo
    expect_true(all(cl$nationality[rows] == fixed[[typo]]),
                label = sprintf("\"%s\" is now \"%s\"", typo, fixed[[typo]]),
                message = sprintf("Add `nationality == \"%s\" ~ \"%s\"` to your `case_when()`.", typo, fixed[[typo]]))
  }
  others <- !(truth$nationality %in% names(fixed))
  expect_true(identical(cl$nationality[others], truth$nationality[others]),
              label = "Other nationalities are unchanged",
              message = "Nations without a typo turned into NA or changed. Add `.default = nationality` to `case_when()`.")
  expect_true(identical(cl$occupation, tolower(truth$occupation)),
              label = "`occupation` is all lower case",
              message = "Add `occupation = tolower(occupation)` to the same `mutate()`.")
}
expect_object("n_jobs_raw", length(unique(truth$occupation)))
expect_object("n_jobs_clean", length(unique(tolower(truth$occupation))),
              message = "Count the spellings in `clean`: `n_distinct(clean$occupation)`.")
