# Exactly `digits` decimals, as text
fmt_num <- function(x, digits = 2) {

}

# "= .032" or "< .001"
fmt_p <- function(p) {

}

# No leading zero: for r, R², eta², V
fmt_bounded <- function(x, digits = 2) {

}

fmt_num(3.1)
fmt_p(0.0321)
fmt_bounded(-0.4512)
