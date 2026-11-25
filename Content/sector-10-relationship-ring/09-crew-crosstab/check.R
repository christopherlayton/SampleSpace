a0 <- utils::read.csv("astronauts.csv")
f0 <- a0[a0$mission_number == 1, ]
era0 <- factor(ifelse(f0$year_of_mission >= 2000, "2000 on", "before 2000"), levels = c("before 2000", "2000 on"))
t0 <- table(era0, f0$sex)
fl <- get_object("first")
expect_true(is.data.frame(fl) && nrow(fl) == nrow(f0) && is.factor(fl$era) &&
              identical(levels(fl$era), c("before 2000", "2000 on")) && identical(as.vector(table(fl$era)), as.vector(table(era0))),
            label = "`first` has one row per astronaut and an `era` factor, earlier era first",
            message = "`mutate(era = factor(ifelse(year_of_mission >= 2000, \"2000 on\", \"before 2000\"), levels = c(\"before 2000\", \"2000 on\")))`.")
ct <- get_object("crew_table")
expect_true(inherits(ct, "table") && identical(dim(ct), c(2L, 2L)) && identical(as.vector(ct), as.vector(t0)),
            label = "`crew_table` counts era (rows) by sex (columns)", message = "`table(first$era, first$sex)`.")
rp <- get_object("row_pct")
expect_true(is.numeric(rp) && length(rp) == 4 && isTRUE(all.equal(as.vector(rp), as.vector(prop.table(t0, 1)))),
            label = "`row_pct` holds each era's proportions",
            message = "`prop.table(crew_table, margin = 1)`: margin 1 means each row sums to 1.")
x0 <- chisq.test(t0, correct = FALSE)
ts <- get_object("test")
expect_true(inherits(ts, "htest") && isTRUE(all.equal(unname(ts$statistic), unname(x0$statistic))),
            label = "`test` is Pearson's χ² without the continuity correction",
            message = "`chisq.test(crew_table, correct = FALSE)`.")
expect_object("expected_ok", all(x0$expected >= 5), message = "`all(test$expected >= 5)`.")
ar <- get_object("adj_resid")
expect_true(is.numeric(ar) && length(ar) == 4 && isTRUE(all.equal(as.vector(ar), as.vector(x0$stdres))),
            label = "`adj_resid` holds the adjusted residuals", message = "`test$stdres`.")
vv <- get_object("v")
expect_true(inherits(vv, "effectsize_table") && isTRUE(all.equal(vv$Cramers_v, sqrt(unname(x0$statistic) / sum(t0)))),
            label = "`v` is the unadjusted Cramér's V",
            message = "`cramers_v(crew_table, adjust = FALSE)`: the default applies a bias adjustment SPSS doesn't.")
