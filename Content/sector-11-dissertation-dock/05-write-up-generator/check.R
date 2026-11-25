call_fn <- function(name, ...) {
  f <- get_object(name)
  if (!is.function(f)) return(NA_character_)
  out <- tryCatch(f(...), error = function(e) NA_character_)
  if (is.character(out) && length(out) == 1) out else NA_character_
}
welch <- t.test(extra ~ group, data = sleep)
d1 <- effectsize::cohens_d(extra ~ group, data = sleep)$Cohens_d
expect_true(!is.na(call_fn("apa_t", welch, d1)), label = "`apa_t()` returns one piece of text",
            message = "`apa_t(test, d)` should return a single string, e.g. with `sprintf()`.")
expect_apa(call_fn("apa_t", welch, d1), welch, c(d = d1),
           label = "`apa_t()` reports a Welch t-test (sleep data)")
student <- t.test(mpg ~ am, data = mtcars, var.equal = TRUE)
d2 <- effectsize::cohens_d(mpg ~ am, data = mtcars)$Cohens_d
expect_apa(call_fn("apa_t", student, d2), student, c(d = d2),
           label = "`apa_t()` reports a Student t-test with a whole-number df")
r1 <- cor.test(iris$Sepal.Length, iris$Petal.Length)
expect_apa(call_fn("apa_r", r1), r1, label = "`apa_r()` reports a strong correlation")
r2 <- cor.test(mtcars$qsec, mtcars$drat)
expect_apa(call_fn("apa_r", r2), r2, label = "`apa_r()` reports a weak correlation")
tooth_test <- t.test(len ~ supp, data = ToothGrowth)
expect_true(identical(get_object("tooth"), call_fn("apa_t", tooth_test, effectsize::cohens_d(len ~ supp, data = ToothGrowth)$Cohens_d)) &&
              !is.na(get_object("tooth") %||% NA),
            label = "`tooth` holds `apa_t()` for the ToothGrowth test", message = "`tooth <- apa_t(tooth_test, tooth_d)`.")
expect_true(identical(get_object("cars"), call_fn("apa_r", cor.test(mtcars$mpg, mtcars$wt))) && !is.na(get_object("cars") %||% NA),
            label = "`cars` holds `apa_r()` for the mtcars correlation", message = "`cars <- apa_r(cars_test)`.")
