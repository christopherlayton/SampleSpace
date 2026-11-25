truth <- utils::read.csv("astronauts.csv")
first_status <- tapply(truth$military_civilian, truth$number, function(x) x[1])
mean_h <- tapply(truth$hours_mission, truth$number, mean)
pp <- data.frame(number = as.numeric(names(mean_h)), military_civilian = as.character(first_status[names(mean_h)]),
                 mean_hours = as.numeric(mean_h))
p <- get_object("people")
ok_people <- is.data.frame(p) && nrow(p) == nrow(pp) && all(c("number", "military_civilian", "mean_hours") %in% names(p))
expect_true(ok_people, label = "`people` has one row per astronaut",
            message = paste("564 rows, one per `number`, with `military_civilian` and `mean_hours`:",
                            "`summarise(military_civilian = first(military_civilian), mean_hours = mean(hours_mission))`."))
if (ok_people) {
  p <- as.data.frame(p)[order(p$number), ]
  expect_true(isTRUE(all.equal(as.numeric(p$mean_hours), pp$mean_hours)),
              label = "`mean_hours` is each astronaut's mean mission length",
              message = "`mean_hours = mean(hours_mission)` inside `summarise()`.")
}
gs <- get_object("group_stats")
want_mean <- tapply(pp$mean_hours, pp$military_civilian, mean)
ok_gs <- is.data.frame(gs) && nrow(gs) == 2 && all(c("military_civilian", "n", "mean", "sd", "median") %in% names(gs))
expect_true(ok_gs && isTRUE(all.equal(as.numeric(gs$mean[order(gs$military_civilian)]), as.numeric(want_mean))) &&
              isTRUE(all.equal(as.numeric(gs$n[order(gs$military_civilian)]), as.numeric(table(pp$military_civilian)))),
            label = "`group_stats` describes both groups",
            message = "Group `people` by `military_civilian` and `summarise(n = n(), mean = ..., sd = ..., median = ...)` of `mean_hours`.")
lv <- car::leveneTest(mean_hours ~ factor(military_civilian), data = pp, center = mean)
l <- get_object("levene")
expect_true(is.data.frame(l) && isTRUE(all.equal(l$"F value"[1], lv$"F value"[1])),
            label = "`levene` is SPSS's Levene test",
            message = "`leveneTest(mean_hours ~ factor(military_civilian), data = people, center = mean)`.")
w <- t.test(mean_hours ~ military_civilian, data = pp)
we <- get_object("welch")
expect_true(inherits(we, "htest") && isTRUE(all.equal(unname(we$statistic), unname(w$statistic))) &&
              isTRUE(all.equal(unname(we$parameter), unname(w$parameter))),
            label = "`welch` is Welch's t-test on one row per person",
            message = "`t.test(mean_hours ~ military_civilian, data = people)`: use `people`, not the mission rows.")
dd <- effectsize::cohens_d(mean_hours ~ military_civilian, data = pp)
dl <- get_object("d")
expect_true(inherits(dl, "effectsize_table") && isTRUE(all.equal(dl$Cohens_d, dd$Cohens_d)),
            label = "`d` is Cohen's d", message = "`cohens_d(mean_hours ~ military_civilian, data = people)`.")
expect_object("decision", if (w$p.value < 0.05) "reject" else "fail to reject",
              message = "Compare Welch's p with .05: below it, \"reject\"; otherwise \"fail to reject\".")
