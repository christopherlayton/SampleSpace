try_fn <- function(name, ...) {
  f <- get_object(name)
  if (!is.function(f)) return(NULL)
  tryCatch(f(...), error = function(e) NULL)
}
expect_true(identical(try_fn("fmt_num", 3.1), "3.10") && identical(try_fn("fmt_num", 0.5), "0.50") &&
              identical(try_fn("fmt_num", 1051.38, 1), "1051.4") && identical(try_fn("fmt_num", -0.3149), "-0.31"),
            label = "`fmt_num()` keeps trailing zeros",
            message = "`fmt_num(3.1)` should give \"3.10\" and `fmt_num(1051.38, 1)` \"1051.4\": use `formatC(x, format = \"f\", digits = digits)`.")
expect_true(identical(try_fn("fmt_p", 0.0321), "= .032") && identical(try_fn("fmt_p", 0.5), "= .500") &&
              identical(try_fn("fmt_p", 0.0012), "= .001"),
            label = "`fmt_p()` writes an exact p without a leading zero",
            message = "`fmt_p(0.0321)` should give \"= .032\" and `fmt_p(0.5)` \"= .500\".")
expect_true(identical(try_fn("fmt_p", 0.00002), "< .001") && identical(try_fn("fmt_p", 0.000999), "< .001"),
            label = "`fmt_p()` writes \"< .001\" below .001",
            message = "Below .001, `fmt_p()` should give \"< .001\": test `if (p < .001)` first.")
expect_true(identical(try_fn("fmt_bounded", 0.4512), ".45") && identical(try_fn("fmt_bounded", -0.8677), "-.87") &&
              identical(try_fn("fmt_bounded", 0.1262, 3), ".126"),
            label = "`fmt_bounded()` drops the leading zero and keeps a minus sign",
            message = "`fmt_bounded(-0.8677)` should give \"-.87\": `sub(\"^(-?)0\\\\.\", \"\\\\1.\", fmt_num(x, digits))`.")
expect_true(grepl("fmt_num", paste(deparse(get_object("fmt_p")), collapse = " ")), label = "`fmt_p()` reuses `fmt_num()`",
            message = "Build `fmt_p()` on `fmt_num(p, 3)` so the rounding rule lives in one place.")
