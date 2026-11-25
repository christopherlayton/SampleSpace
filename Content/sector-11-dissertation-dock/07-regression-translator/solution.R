fit <- lm(morale_score ~ sleep_hours, data = sm)
fit_summary <- summary(fit)

b <- coef(fit)[["sleep_hours"]]
beta <- b * sd(sm$sleep_hours) / sd(sm$morale_score)
f <- fit_summary$fstatistic
p <- pf(f[["value"]], f[["numdf"]], f[["dendf"]], lower.tail = FALSE)

write_up <- sprintf("*F*(%s, %s) = %s, *p* %s, *R*² = %s, *b* = %s", f[["numdf"]], f[["dendf"]],
                    fmt_num(f[["value"]]), fmt_p(p), fmt_bounded(fit_summary$r.squared), fmt_num(b))
write_up
