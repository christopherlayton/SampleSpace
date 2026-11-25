truth <- utils::read.csv("wellbeing_survey.csv")
se <- function(x) sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x)))
f <- get_object("se_mean")
expect_true(is.function(f), label = "`se_mean` is a function",
            message = "Write it as `se_mean <- function(x) { ... }`.")
if (is.function(f)) {
  probe <- c(2, 4, 4, 4, 5, 5, 7, 9)
  got <- tryCatch(f(probe), error = function(e) NULL)
  expect_true(isTRUE(all.equal(got, se(probe))), label = "`se_mean()` gives SD / √n",
              message = "For complete data it should return `sd(x) / sqrt(length(x))`.")
  got_na <- tryCatch(f(c(probe, NA, NA)), error = function(e) NULL)
  expect_true(isTRUE(all.equal(got_na, se(probe))), label = "`se_mean()` ignores missing values",
              message = paste("With NAs it should give the same answer as without them: use `sd(x, na.rm = TRUE)`",
                              "and count n with `sum(!is.na(x))`, not `length(x)`."))
}
expect_object("se_pre", se(truth$anxiety_pre), message = "SPSS shows .795. Use `se_mean(survey$anxiety_pre)`.")
expect_object("se_post", se(truth$anxiety_post),
              message = "SPSS shows 1.075 (37 people). Use `se_mean(survey$anxiety_post)`; n must leave out the 3 missing values.")
