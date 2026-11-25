# Makes the simulated datasets used by levels in Sectors 2–10. The data are invented
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
content <- file.path(root, "Content")
survey_levels <- c(file.path(docks, c("06-read-csv", "07-hull-breach", "12-docking-review")),
                   file.path(content, "sector-04-descriptive-drift", c("05-describe-everything", "06-descriptives-translator")),
                   file.path(content, "sector-05-plot-nebula", "06-error-bars"),
                   file.path(content, "sector-06-probability-expanse", "08-standard-error-translator"),
                   file.path(content, "sector-07-inference-station", "03-interval-by-hand"),
                   file.path(content, "sector-08-means-cluster",
                             c("02-one-sample", "03-independent-groups", "04-assumption-checks",
                               "06-paired-burn", "08-backwards-formula")))
for (level in survey_levels) {
  dir.create(level, showWarnings = FALSE)
  write.csv(survey, file.path(level, "wellbeing_survey.csv"), row.names = FALSE, na = "")
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
sav_levels <- c(file.path(docks, c("08-read-sav", "09-value-labels", "10-frequency-translator")),
                file.path(content, "sector-08-means-cluster",
                          c("05-t-test-translator", "07-effect-size", "09-apa-report")),
                file.path(content, "sector-10-relationship-ring", "10-crosstabs-translator"))
for (level in sav_levels) {
  dir.create(level, showWarnings = FALSE)
  haven::write_sav(teach, file.path(level, "teaching_study.sav"))
}
# --- crew_morale.csv: a six-item morale scale, 48 participants, two items reverse-worded ----
# Used by Wrangler's Reach (reverse-scoring, composites, missing data).
set.seed(1969)
k <- 48
reach <- file.path(root, "Content", "sector-03-wranglers-reach")
programme <- sample(rep(c("Mentoring", "Standard"), each = k / 2))
latent <- rnorm(k, ifelse(programme == "Mentoring", 0.4, -0.2), 1)
item <- function(reverse = FALSE) {
  x <- round(pmin(pmax(3 + 0.9 * latent + rnorm(k, 0, 0.7), 1), 5))
  if (reverse) 6 - x else x
}
morale <- data.frame(
  id = sprintf("C%02d", 1:k),
  programme = programme,
  m1 = item(), m2 = item(reverse = TRUE), m3 = item(), m4 = item(), m5 = item(reverse = TRUE), m6 = item(),
  sleep_hours = round(pmin(pmax(rnorm(k, 6.8 + 0.3 * latent, 0.9), 4), 9.5), 1)
)
morale$m3[c(6, 30)] <- NA
morale$m5[c(14)] <- NA
morale$m6[c(30, 41)] <- NA
morale$sleep_hours[c(9, 22)] <- NA
for (level in c("06-reverse-thrusters", "07-missing-cargo", "09-reshape-bay")) {
  dir.create(file.path(reach, level), showWarnings = FALSE)
  write.csv(morale, file.path(reach, level, "crew_morale.csv"), row.names = FALSE, na = "")
}

# --- sleep_morale.csv: complete cases of sleep and the morale composite (Least-Squares Fit lab) ---
items <- cbind(morale$m1, 6 - morale$m2, morale$m3, morale$m4, 6 - morale$m5, morale$m6)
fit_data <- data.frame(id = morale$id, sleep_hours = morale$sleep_hours,
                       morale_score = round(rowMeans(items, na.rm = TRUE), 2))
fit_data <- fit_data[complete.cases(fit_data), ]
ring_dir <- file.path(content, "sector-10-relationship-ring")
for (level in c("03-cor-test", "04-least-squares-fit", "05-simple-regression")) {
  dir.create(file.path(ring_dir, level), showWarnings = FALSE)
  write.csv(fit_data, file.path(ring_dir, level, "sleep_morale.csv"), row.names = FALSE)
}

# --- pd_study.csv: three professional-development programmes, 60 teachers ----------------
# Teacher self-efficacy (1-9) before (t1), at the end (t2) and at a follow-up (t3); a balanced
# 3 x 2 design (programme x experience, 10 per cell) for Variance Rift, plus workload and years
# of teaching for multiple regression in the Relationship Ring.
set.seed(1987)
k <- 60
programme <- rep(c("Workshop", "Coaching", "Online"), each = 20)
experience <- rep(rep(c("Early career", "Experienced"), each = 10), 3)
ord <- sample(k)
programme <- programme[ord]
experience <- experience[ord]
years <- ifelse(experience == "Early career", sample(1:4, k, TRUE), sample(5:28, k, TRUE))
t1 <- rnorm(k, 5.4 + 0.4 * (experience == "Experienced"), 0.8)
coached_novice <- programme == "Coaching" & experience == "Early career"
t2 <- t1 + c(Workshop = 0.4, Coaching = 1.1, Online = 0.25)[programme] + 0.6 * coached_novice + rnorm(k, 0, 0.55)
workload <- round(rnorm(k, 47, 6))
t3 <- t1 + c(Workshop = 0.15, Coaching = 0.85, Online = 0.0)[programme] + 0.4 * coached_novice -
  0.03 * (workload - 47) + rnorm(k, 0, 0.6)
bounded <- function(x) round(pmin(pmax(x, 1), 9), 2)
pd <- data.frame(id = sprintf("T%02d", 1:k), programme, experience, years_teaching = years,
                 workload_hours = workload, efficacy_t1 = bounded(t1), efficacy_t2 = bounded(t2),
                 efficacy_t3 = bounded(t3))
rift <- file.path(content, "sector-09-variance-rift")
pd_levels <- c(file.path(rift, c("02-anova-splitter", "03-one-way", "06-post-hoc", "07-anova-assumptions",
                                 "08-anova-translator", "09-two-factors", "10-repeated-measures",
                                 "11-broken-splitter")),
               file.path(ring_dir, c("07-multiple-regression", "11-tangled-threads")))
for (level in pd_levels) {
  dir.create(level, showWarnings = FALSE)
  write.csv(pd, file.path(level, "pd_study.csv"), row.names = FALSE)
}

cat("Wrote wellbeing_survey.csv, teaching_study.sav, crew_morale.csv, sleep_morale.csv and pd_study.csv\n")
