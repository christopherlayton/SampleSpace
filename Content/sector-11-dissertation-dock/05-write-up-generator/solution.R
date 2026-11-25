library(effectsize)

apa_t <- function(test, d) {
  sprintf("*t*(%s) = %s, *p* %s, *d* = %s", fmt_df(test$parameter), fmt_num(test$statistic),
          fmt_p(test$p.value), fmt_num(d))
}

apa_r <- function(test) {
  sprintf("*r*(%s) = %s, *p* %s", fmt_df(test$parameter), fmt_bounded(test$estimate), fmt_p(test$p.value))
}

tooth_test <- t.test(len ~ supp, data = ToothGrowth)
tooth_d <- cohens_d(len ~ supp, data = ToothGrowth)$Cohens_d
tooth <- apa_t(tooth_test, tooth_d)
tooth

cars_test <- cor.test(mtcars$mpg, mtcars$wt)
cars <- apa_r(cars_test)
cars
