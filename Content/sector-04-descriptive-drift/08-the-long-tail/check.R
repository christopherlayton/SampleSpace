truth <- utils::read.csv("astronauts.csv")
h <- truth$hours_mission
c0 <- get_object("centre")
want <- c(mean_hours = mean(h), median_hours = median(h), sd_hours = sd(h), iqr_hours = IQR(h))
ok <- is.data.frame(c0) && nrow(c0) == 1 && all(names(want) %in% names(c0))
expect_true(ok, label = "`centre` has mean_hours, median_hours, sd_hours and iqr_hours",
            message = "One `summarise()` with four named summaries.")
if (ok) {
  expect_true(isTRUE(all.equal(unlist(as.data.frame(c0)[names(want)]), want)),
              label = "`centre` has the right values",
              message = "Check each summary: `mean()`, `median()`, `sd()` and `IQR()` of `hours_mission`.")
}
l <- get_object("longest")
top <- truth[which.max(h), ]
expect_true(is.data.frame(l) && nrow(l) == 1 && identical(names(l), c("name", "year_of_mission", "hours_mission")) &&
              l$name == top$name,
            label = "`longest` is the record mission",
            message = "`slice_max(hours_mission, n = 1)`, then `select(name, year_of_mission, hours_mission)`.")
sentence <- sprintf("Mission length was positively skewed (Mdn = %.0f h, IQR = %.0f h; M = %.0f h, SD = %.0f h).",
                    median(h), IQR(h), mean(h), sd(h))
expect_object("apa", sentence,
              message = paste("`apa` should read exactly:", sentence,
                              "Fill it with `sprintf()` and four `%.0f` placeholders, in the order Mdn, IQR, M, SD."))
expect_called("sprintf")
