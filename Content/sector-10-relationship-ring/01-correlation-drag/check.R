x <- get_object("x")
y <- get_object("y")
ok <- is.numeric(x) && is.numeric(y) && length(x) == 20 && length(y) == 20
expect_true(ok, label = "`x` and `y` hold 20 values each",
            message = "Keep the first two lines that make `x` and `y`.")
if (ok) {
  expect_object("r_cloud", cor(x, y), message = "Use `cor(x, y)`.")
  expect_object("x2", c(x, 9.6), message = "Add the outlier's x to the end: `x2 <- c(x, 9.6)`.")
  expect_object("y2", c(y, 0.4), message = "Add the outlier's y to the end: `y2 <- c(y, 0.4)`.")
  expect_object("r_outlier", cor(c(x, 9.6), c(y, 0.4)), message = "`cor(x2, y2)`.")
  expect_object("rho_outlier", cor(c(x, 9.6), c(y, 0.4), method = "spearman"),
                message = "Spearman's rho: `cor(x2, y2, method = \"spearman\")`.")
}
expect_plot(message = "Draw the points with `plot(x2, y2)`.")
