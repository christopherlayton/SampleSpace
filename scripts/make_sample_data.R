# Makes the simulated datasets used by Data Frame Docks levels. The data are invented
# but shaped like a typical dissertation study. Rerun after changing it:
#   Rscript --no-init-file scripts/make_sample_data.R
# then scripts/validate_content.sh, because level checks depend on these values.

root <- normalizePath(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))), ".."))
docks <- file.path(root, "Content", "sector-02-data-frame-docks")

# --- wellbeing_survey.csv: a two-group mindfulness study, 40 students -----------------
set.seed(2026)
n <- 40
group <- sample(rep(c("Control", "Mindfulness"), each = n / 2))
anxiety_pre <- round(pmin(pmax(rnorm(n, 30, 6), 10), 50))
effect <- ifelse(group == "Mindfulness", 5, 1)
anxiety_post <- round(pmin(pmax(anxiety_pre - effect + rnorm(n, 0, 3), 10), 50))
survey <- data.frame(
  id = sprintf("S%02d", 1:n),
  group = group,
  gender = sample(c("Woman", "Man", "Non-binary"), n, replace = TRUE, prob = c(0.55, 0.4, 0.05)),
  age = pmax(18, round(rnorm(n, 23, 4))),
  year = sample(1:4, n, replace = TRUE),
  anxiety_pre = anxiety_pre,
  anxiety_post = anxiety_post,
  satisfaction = sample(1:5, n, replace = TRUE, prob = c(0.05, 0.1, 0.25, 0.35, 0.25))
)
survey$anxiety_post[c(7, 19, 33)] <- NA   # three students missed the post-test
survey$satisfaction[c(12, 27)] <- NA
survey$age[24] <- NA
for (level in c("06-read-csv", "07-hull-breach", "12-docking-review")) {
  write.csv(survey, file.path(docks, level, "wellbeing_survey.csv"), row.names = FALSE, na = "")
}

# --- teaching_study.sav: an SPSS file with value labels and a user-missing code -------
set.seed(711)
m <- 30
method <- sample(rep(1:2, each = m / 2))
score <- round(pmin(pmax(rnorm(m, 68 + 6 * (method == 2), 9), 30), 100))
anxiety <- sample(1:5, m, replace = TRUE)
anxiety[c(5, 22)] <- 9  # "No answer", declared missing in SPSS
teach <- data.frame(
  id = 1:m,
  method = haven::labelled(method, c("Lecture" = 1, "Active learning" = 2), label = "Teaching method"),
  gender = haven::labelled(sample(1:3, m, replace = TRUE, prob = c(0.5, 0.45, 0.05)),
                           c("Woman" = 1, "Man" = 2, "Non-binary" = 3), label = "Gender"),
  score = structure(score, label = "Final exam score (%)"),
  anxiety = haven::labelled_spss(anxiety,
                                 c("Not at all" = 1, "A little" = 2, "Moderately" = 3,
                                   "Very" = 4, "Extremely" = 5, "No answer" = 9),
                                 na_values = 9, label = "Exam anxiety")
)
for (level in c("08-read-sav", "09-value-labels", "10-frequency-translator")) {
  haven::write_sav(teach, file.path(docks, level, "teaching_study.sav"))
}
cat("Wrote wellbeing_survey.csv and teaching_study.sav\n")
