study <- data.frame(
  id = sprintf("P%02d", 1:12),
  condition = rep(c("control", "treatment"), times = 6),
  age = c(22, 31, 19, 27, 24, 35, 29, 21, 26, 33, 20, 28),
  score = c(54, 67, 49, 72, 58, 75, 61, 70, 52, 69, 47, 74)
)
