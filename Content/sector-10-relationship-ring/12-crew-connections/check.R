a0 <- utils::read.csv("astronauts.csv")
ids <- sort(unique(a0$number))
mis0 <- as.numeric(table(a0$number)[as.character(ids)])
eva0 <- as.numeric(tapply(a0$eva_hrs_mission, a0$number, sum)[as.character(ids)])
firsts <- a0[!duplicated(a0$number), ]
firsts <- firsts[match(ids, firsts$number), ]
nat0 <- ifelse(firsts$nationality %in% c("U.S.", "U.S.S.R/Russia"), firsts$nationality, "Other")
pp <- get_object("people")
ok_p <- is.data.frame(pp) && nrow(pp) == length(ids) &&
  all(c("number", "missions", "eva_hours", "military_civilian", "nation") %in% names(pp))
if (ok_p) {
  pp <- as.data.frame(pp)[order(pp$number), ]
  ok_p <- isTRUE(all.equal(as.numeric(pp$missions), mis0)) && isTRUE(all.equal(as.numeric(pp$eva_hours), eva0)) &&
    identical(as.character(pp$nation), nat0)
}
expect_true(ok_p, label = "`people` has one row per astronaut with missions, EVA hours, status and nation",
            message = paste("`summarise(missions = n(), eva_hours = sum(eva_hrs_mission), military_civilian = first(military_civilian),",
                            "nationality = first(nationality))`, then `mutate(nation = case_when(...))`."))
expect_ggplot("p", geom = "jitter", aes = c(x = "missions", y = "eva_hours"),
              message = "`ggplot(people, aes(x = missions, y = eva_hours)) + geom_jitter()`.")
pr <- get_object("pearson")
expect_true(inherits(pr, "htest") && grepl("Pearson", pr$method) && isTRUE(all.equal(unname(pr$estimate), cor(mis0, eva0))),
            label = "`pearson` tests missions with EVA hours", message = "`cor.test(people$missions, people$eva_hours)`.")
sp0 <- cor.test(mis0, eva0, method = "spearman", exact = FALSE)
sp <- get_object("spearman")
expect_true(inherits(sp, "htest") && grepl("Spearman", sp$method) && isTRUE(all.equal(unname(sp$estimate), unname(sp0$estimate))),
            label = "`spearman` is Spearman's rho", message = "Add `method = \"spearman\", exact = FALSE`.")
m0 <- lm(eva0 ~ mis0)
m <- get_object("model")
expect_true(inherits(m, "lm") && isTRUE(all.equal(unname(coef(m)), unname(coef(m0)))),
            label = "`model` regresses EVA hours on missions", message = "`lm(eva_hours ~ missions, data = people)`.")
expect_object("b", unname(coef(m0)[2]), tolerance = 1e-8, check_attributes = FALSE, message = "`unname(coef(model)[\"missions\"])`.")
t0 <- table(nat0, firsts$military_civilian)
ct <- get_object("crosstab")
expect_true(inherits(ct, "table") && identical(dim(ct), c(3L, 2L)) && setequal(as.vector(ct), as.vector(t0)) &&
              sum(ct) == sum(t0),
            label = "`crosstab` counts nation (3) by military status (2)", message = "`table(people$nation, people$military_civilian)`.")
x0 <- chisq.test(t0)
ch <- get_object("chi")
expect_true(inherits(ch, "htest") && isTRUE(all.equal(unname(ch$statistic), unname(x0$statistic))),
            label = "`chi` is the χ² test of independence", message = "`chisq.test(crosstab)`.")
vv <- get_object("v")
expect_true(inherits(vv, "effectsize_table") && isTRUE(all.equal(vv$Cramers_v, sqrt(unname(x0$statistic) / sum(t0)))),
            label = "`v` is the unadjusted Cramér's V", message = "`cramers_v(crosstab, adjust = FALSE)`.")
pr0 <- cor.test(mis0, eva0)
expect_object("decision_r", if (pr0$p.value < 0.05) "reject" else "fail to reject",
              message = "Compare Pearson's p with .05: below it, \"reject\"; otherwise \"fail to reject\".")
expect_object("decision_chi", if (x0$p.value < 0.05) "reject" else "fail to reject",
              message = "Compare the χ² test's p with .05.")
