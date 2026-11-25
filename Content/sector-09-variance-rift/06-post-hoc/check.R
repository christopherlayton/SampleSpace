pd0 <- utils::read.csv("pd_study.csv")
pd0$programme <- factor(pd0$programme, levels = c("Workshop", "Coaching", "Online"))
fit0 <- aov(efficacy_t2 ~ programme, data = pd0)
tk0 <- TukeyHSD(fit0)$programme
tk <- get_object("tukey")
expect_true(inherits(tk, "TukeyHSD") && !is.null(tk$programme) &&
              isTRUE(all.equal(unname(tk$programme[, "p adj"]), unname(tk0[, "p adj"]))),
            label = "`tukey` is Tukey's HSD for programme",
            message = "`tukey <- TukeyHSD(fit)`: give it the aov model, not its summary.")
b0 <- pairwise.t.test(pd0$efficacy_t2, pd0$programme, p.adjust.method = "bonferroni")
h0 <- pairwise.t.test(pd0$efficacy_t2, pd0$programme, p.adjust.method = "holm")
b <- get_object("pairs_bonf")
h <- get_object("pairs_holm")
expect_true(inherits(b, "pairwise.htest") && identical(b$p.adjust.method, "bonferroni") &&
              isTRUE(all.equal(b$p.value, b0$p.value)),
            label = "`pairs_bonf` is Bonferroni-corrected pairwise t-tests",
            message = "`pairwise.t.test(pd$efficacy_t2, pd$programme, p.adjust.method = \"bonferroni\")`.")
expect_true(inherits(h, "pairwise.htest") && identical(h$p.adjust.method, "holm") &&
              isTRUE(all.equal(h$p.value, h0$p.value)),
            label = "`pairs_holm` is Holm-corrected pairwise t-tests",
            message = "The same call with `p.adjust.method = \"holm\"`.")
expect_object("differ", rownames(tk0)[tk0[, "p adj"] < 0.05],
              message = "`rownames(tukey$programme)[tukey$programme[, \"p adj\"] < 0.05]`: the pairs whose adjusted p is below .05.")
