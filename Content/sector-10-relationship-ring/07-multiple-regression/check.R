pd0 <- utils::read.csv("pd_study.csv")
b0 <- lm(efficacy_t3 ~ efficacy_t1, data = pd0)
m0 <- lm(efficacy_t3 ~ efficacy_t1 + workload_hours + years_teaching, data = pd0)
b <- get_object("base")
m <- get_object("model")
expect_true(inherits(b, "lm") && isTRUE(all.equal(unname(coef(b)), unname(coef(b0)))),
            label = "`base` is block 1: efficacy_t3 on efficacy_t1",
            message = "`base <- lm(efficacy_t3 ~ efficacy_t1, data = pd)`.")
expect_true(inherits(m, "lm") && length(coef(m)) == 4 &&
              isTRUE(all.equal(unname(coef(m)[names(coef(m0))]), unname(coef(m0)))),
            label = "`model` adds workload_hours and years_teaching",
            message = "`lm(efficacy_t3 ~ efficacy_t1 + workload_hours + years_teaching, data = pd)`.")
expect_object("r2", summary(m0)$r.squared, tolerance = 1e-10, message = "`summary(model)$r.squared`.")
expect_object("adj_r2", summary(m0)$adj.r.squared, tolerance = 1e-10, message = "`summary(model)$adj.r.squared`.")
expect_object("r2_change", summary(m0)$r.squared - summary(b0)$r.squared, tolerance = 1e-10,
              message = "The full model's R² minus block 1's: `r2 - summary(base)$r.squared`.")
ct <- get_object("change_test")
ct0 <- anova(b0, m0)
expect_true(inherits(ct, "anova") && nrow(ct) == 2 && isTRUE(all.equal(ct$F[2], ct0$F[2])),
            label = "`change_test` is the F test of the R² change",
            message = "`anova(base, model)`: the smaller model first.")
bt <- get_object("betas")
sp0 <- effectsize::standardize_parameters(m0)
expect_true(inherits(bt, "parameters_standardized") && isTRUE(all.equal(bt$Std_Coefficient, sp0$Std_Coefficient)),
            label = "`betas` holds the standardised coefficients", message = "`standardize_parameters(model)`.")
expect_object("vifs", car::vif(m0), tolerance = 1e-8, message = "`vif(model)` from car.")
expect_plot(n = 2, message = "Draw both: `plot(model, which = 1)` and `plot(model, which = 2)`.")
