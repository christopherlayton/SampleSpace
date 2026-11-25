truth <- utils::read.csv("astronauts.csv")
w <- truth$sex[truth$mission_number == 1] == "female"
p <- mean(w)
women <- get_object("women")
expect_true(is.logical(women) && length(women) == length(w) && isTRUE(all(women == w)),
            label = "`women` marks each female first-time flyer",
            message = "`first$sex == \"female\"` gives TRUE or FALSE for each of the 564 astronauts.")
expect_object("p_log", p, message = "`mean(women)`: 64 of 564, about .113.")
check_props <- function(name, n) {
  x <- get_object(name)
  ok <- is.numeric(x) && length(x) == 2000
  expect_true(ok && all(x >= 0 & x <= 1) && abs(mean(x) - p) < 0.01 &&
                abs(sd(x) - sqrt(p * (1 - p) / n)) < 0.25 * sqrt(p * (1 - p) / n),
              label = sprintf("`%s` holds 2,000 crew proportions for crews of %d", name, n),
              message = sprintf("`replicate(2000, mean(sample(women, size = %d, replace = TRUE)))`.", n))
  ok
}
ok50 <- check_props("props_50", 50)
ok200 <- check_props("props_200", 200)
expect_true(ok50 && ok200 && isTRUE(all.equal(get_object("se_50"), sd(get_object("props_50")))) &&
              isTRUE(all.equal(get_object("se_200"), sd(get_object("props_200")))),
            label = "`se_50` and `se_200` are the SDs of the proportions",
            message = "The simulated SE is the SD of the crew proportions: `sd(props_50)` and `sd(props_200)`.")
expect_true(ok50 && ok200 && isTRUE(all.equal(get_object("se_ratio"), get_object("se_50") / get_object("se_200"))),
            label = "`se_ratio` is se_50 / se_200",
            message = "`se_ratio <- se_50 / se_200`. Four times the crew should give about half the SE, so it's near 2.")
expect_object("se_50_formula", sqrt(p * (1 - p) / 50),
              message = "`sqrt(p_log * (1 - p_log) / 50)`.")
expect_plot(message = "Finish with `hist(props_50)`.")
