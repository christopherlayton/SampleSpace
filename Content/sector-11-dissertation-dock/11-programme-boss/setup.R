fmt_num <- function(x, digits = 2) formatC(x, format = "f", digits = digits)
fmt_p <- function(p) if (p < .001) "< .001" else paste("=", sub("^0", "", fmt_num(p, 3)))
fmt_bounded <- function(x, digits = 2) sub("^(-?)0\\.", "\\1.", fmt_num(x, digits))
