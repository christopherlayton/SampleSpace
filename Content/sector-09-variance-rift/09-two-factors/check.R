pd0 <- utils::read.csv("pd_study.csv")
pd0$programme <- factor(pd0$programme, levels = c("Workshop", "Coaching", "Online"))
want0 <- aggregate(efficacy_t2 ~ programme + experience, data = pd0, mean)
cl <- get_object("cells")
ok_c <- is.data.frame(cl) && nrow(cl) == 6 && all(c("programme", "experience", "mean") %in% names(cl))
if (ok_c) {
  key_w <- paste(want0$programme, want0$experience)
  key_g <- paste(cl$programme, cl$experience)
  ok_c <- setequal(key_w, key_g) && isTRUE(all.equal(as.numeric(cl$mean[match(key_w, key_g)]), want0$efficacy_t2))
}
expect_true(ok_c, label = "`cells` holds the six cell means",
            message = "`pd |> group_by(programme, experience) |> summarise(n = n(), mean = mean(efficacy_t2), .groups = \"drop\")`.")
tab0 <- summary(aov(efficacy_t2 ~ programme * experience, data = pd0))[[1]]
f2 <- get_object("fit2")
expect_true(inherits(f2, "aov") && nrow(summary(f2)[[1]]) == 4 &&
              isTRUE(all.equal(summary(f2)[[1]]$"F value"[1:3], tab0$"F value"[1:3])),
            label = "`fit2` has both main effects and the interaction",
            message = "`aov(efficacy_t2 ~ programme * experience, data = pd)`: `*` adds the interaction.")
fa <- get_object("factorial")
expect_true(inherits(fa, "afex_aov") && isTRUE(all.equal(unname(fa$anova_table$F), tab0$"F value"[1:3])),
            label = "`factorial` is the Type III ANOVA from afex",
            message = "`aov_car(efficacy_t2 ~ programme * experience + Error(id), data = pd)`.")
ss <- tab0$"Sum Sq"
pe <- get_object("pes")
expect_true(inherits(pe, "effectsize_table") && "Eta2_partial" %in% names(pe) &&
              isTRUE(all.equal(pe$Eta2_partial, ss[1:3] / (ss[1:3] + ss[4]))),
            label = "`pes` holds partial η² for the three effects",
            message = "`eta_squared(fit2, partial = TRUE)`.")
expect_ggplot("p", geom = "line", aes = c(x = "programme", y = "mean", colour = "experience"),
              message = "`ggplot(cells, aes(x = programme, y = mean, colour = experience, group = experience)) + geom_point() + geom_line()`.")
