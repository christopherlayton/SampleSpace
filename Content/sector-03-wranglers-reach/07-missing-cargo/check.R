truth <- utils::read.csv("crew_morale.csv")
expect_no_error(message = "R still stops with an error. Fix the first one it reports, then run again.")
expect_object("n_sleep", sum(!is.na(truth$sleep_hours)),
              message = "`!= NA` is always NA, so no rows survive. Use `filter(!is.na(sleep_hours))`.")
s <- get_object("sleep_by_programme")
want <- tapply(truth$sleep_hours, truth$programme, mean, na.rm = TRUE)
expect_true(is.data.frame(s) && "mean_sleep" %in% names(s) &&
              isTRUE(all.equal(as.numeric(s$mean_sleep[order(s$programme)]), as.numeric(want))),
            label = "`sleep_by_programme` has each programme's mean sleep",
            message = "Two people skipped the sleep question, so the means are NA. Add `na.rm = TRUE` to `mean()`.")
items <- truth[, c("m1", "m2", "m3", "m4", "m5", "m6")]
expect_object("n_all_items", sum(complete.cases(items)),
              message = paste("`na.omit(morale)` also drops people who only skipped the sleep question.",
                              "Check the six items only, e.g. `filter(if_all(m1:m6, ~ !is.na(.x)))`."))
