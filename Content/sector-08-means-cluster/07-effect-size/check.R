t0 <- haven::read_sav("teaching_study.sav")
t0$method <- haven::as_factor(t0$method)
l <- t0$score[t0$method == "Lecture"]
a <- t0$score[t0$method == "Active learning"]
sp <- sqrt(((length(l) - 1) * var(l) + (length(a) - 1) * var(a)) / (length(l) + length(a) - 2))
act <- get_object("active")
expect_true(is.numeric(act) && length(act) == length(a) && isTRUE(all.equal(sort(as.numeric(act)), sort(as.numeric(a)))),
            label = "`active` holds the active-learning scores",
            message = "Same as `lecture`, with `\"Active learning\"`.")
expect_object("sd_pooled", sp,
              message = "`sqrt(((n1 - 1) * sd(lecture)^2 + (n2 - 1) * sd(active)^2) / (n1 + n2 - 2))`.")
dh <- get_object("d_hand")
expect_true(is.numeric(dh) && length(dh) == 1 && isTRUE(all.equal(abs(as.numeric(dh)), abs((mean(l) - mean(a)) / sp))),
            label = "`d_hand` is the mean difference over the pooled SD",
            message = "`(mean(lecture) - mean(active)) / sd_pooled`.")
expect_true(is.numeric(dh) && length(dh) == 1 && dh < 0, label = "`d_hand` is Lecture − Active learning",
            message = "Subtract the active-learning mean from the lecture mean, so d is negative (lecture scored lower).")
want <- effectsize::cohens_d(score ~ method, data = t0)
dp <- get_object("d_pkg")
expect_true(inherits(dp, "effectsize_table") && isTRUE(all.equal(dp$Cohens_d, want$Cohens_d)),
            label = "`d_pkg` is effectsize's Cohen's d",
            message = "`cohens_d(score ~ method, data = teach)`.")
expect_object("d_ci", c(want$CI_low, want$CI_high), message = "`c(d_pkg$CI_low, d_pkg$CI_high)`.")
