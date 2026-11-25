# Exactly `digits` decimals, as text
fmt_num <- function(x, digits = 2) {
  formatC(x, format = "f", digits = digits)
}

# "= .032" or "< .001"
fmt_p <- function(p) {
  if (p < .001) "< .001" else paste("=", sub("^0", "", fmt_num(p, 3)))
}

# No leading zero: for r, R², eta², V
fmt_bounded <- function(x, digits = 2) {
  sub("^(-?)0\\.", "\\1.", fmt_num(x, digits))
}

fmt_num(3.1)
fmt_p(0.0321)
fmt_bounded(-0.4512)
