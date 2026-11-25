t0 <- haven::read_sav("teaching_study.sav")
t0$method <- haven::as_factor(t0$method)
l <- t0$score[t0$method == "Lecture"]
a <- t0$score[t0$method == "Active learning"]
w <- t.test(score ~ method, data = t0)
dd <- effectsize::cohens_d(score ~ method, data = t0)
r <- get_object("res")
expect_true(inherits(r, "htest") && isTRUE(all.equal(unname(r$parameter), unname(w$parameter))),
            label = "`res` is Welch's t-test of score by method",
            message = "`t.test(score ~ method, data = teach)`, without `var.equal`.")
f <- get_object("fmt_p")
expect_true(is.function(f), label = "`fmt_p` is a function", message = "Write `fmt_p <- function(p) { ... }`.")
if (is.function(f)) {
  try_f <- function(p) tryCatch(f(p), error = function(e) NA)
  expect_true(identical(try_f(0.0108), "= .011") && identical(try_f(0.5), "= .500"),
              label = "`fmt_p()` gives \"= .011\" for 0.0108",
              message = "Three decimals, no leading zero: `paste(\"=\", sub(\"^0\", \"\", sprintf(\"%.3f\", p)))`.")
  expect_true(identical(try_f(0.00002), "< .001"),
              label = "`fmt_p()` gives \"< .001\" for tiny p",
              message = "Anything below .001 is reported as \"< .001\": start with `if (p < 0.001) \"< .001\" else ...`.")
}
fp <- function(p) if (p < 0.001) "< .001" else paste("=", sub("^0", "", sprintf("%.3f", p)))
sentence <- sprintf(paste("Students taught with active learning (M = %.2f, SD = %.2f) scored higher than",
                          "students taught by lecture (M = %.2f, SD = %.2f), t(%.2f) = %.2f, p %s, d = %.2f."),
                    mean(a), sd(a), mean(l), sd(l), unname(w$parameter), abs(unname(w$statistic)),
                    fp(w$p.value), abs(dd$Cohens_d))
expect_object("apa", sentence,
              message = paste("`apa` should read:", sentence,
                              "Give sprintf() the eight values in order: active M and SD, lecture M and SD,",
                              "df, |t|, fmt_p(p), |d|."))
expect_called("sprintf")
