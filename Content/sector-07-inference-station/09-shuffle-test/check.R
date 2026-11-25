truth <- utils::read.csv("astronauts.csv")
f <- truth[truth$mission_number == 1, ]
e0 <- ifelse(f$year_of_mission >= 2000, "2000 on", "before 2000")
w0 <- f$sex == "female"
obs <- mean(w0[e0 == "2000 on"]) - mean(w0[e0 == "before 2000"])
expect_object("observed", obs,
              message = "2000 on minus before 2000: `mean(woman[era == \"2000 on\"]) - mean(woman[era == \"before 2000\"])`.")
s <- get_object("shuffled")
ok <- is.numeric(s) && length(s) == 5000
expect_true(ok, label = "`shuffled` holds 5,000 gaps",
            message = "Each repeat shuffles the labels with `sample(era)` and returns the gap computed with the shuffled labels.")
expect_true(ok && abs(mean(s)) < 0.01 && sd(s) > 0.015 && sd(s) < 0.045,
            label = "The gaps come from shuffled labels",
            message = paste("Shuffled gaps should centre on 0. Inside `replicate()`, use the *shuffled* labels",
                            "(e.g. `e <- sample(era)`) in both `mean()`s, not `era`."))
p <- get_object("p_shuffle")
expect_true(ok && isTRUE(all.equal(p, mean(abs(s) >= abs(obs)))),
            label = "`p_shuffle` is the two-sided share",
            message = "Compare sizes, ignoring sign: `mean(abs(shuffled) >= abs(observed))`.")
want <- if (is.numeric(p) && length(p) == 1 && p < 0.05) "reject" else "fail to reject"
expect_object("decision", want,
              message = "Compare `p_shuffle` with .05: below it, \"reject\"; otherwise \"fail to reject\".")
expect_plot(message = "Draw `hist(shuffled)`, then `abline(v = observed)`.")
expect_called("abline")
