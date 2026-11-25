library(effectsize)

apa_t <- function(test, d) {

}

apa_r <- function(test) {

}

tooth_test <- t.test(len ~ supp, data = ToothGrowth)
tooth_d <- cohens_d(len ~ supp, data = ToothGrowth)$Cohens_d
tooth <- 

cars_test <- cor.test(mtcars$mpg, mtcars$wt)
cars <- 
