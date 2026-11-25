truth <- utils::read.csv("astronauts.csv")
f <- truth[truth$mission_number == 1, ]
f$age <- f$year_of_mission - f$year_of_birth
ref_t <- t.test(age ~ sex, data = f)
ref_d <- effectsize::cohens_d(age ~ sex, data = f)$Cohens_d
ref_r <- suppressWarnings(cor.test(f$age, f$total_number_of_missions, method = "spearman", exact = FALSE))
chunks <- document_chunks()
doc <- document_text()

step(1)
yaml <- document_yaml()
expect_true(is.character(yaml$title) && nchar(trimws(yaml$title)) > 3 && is.character(yaml$author) && nzchar(trimws(yaml$author)),
            label = "The YAML header has a title and an author",
            message = "Fill in `title:` and `author:` (in quotes) at the top.")
setup <- if (length(chunks)) chunks[[1]] else NULL
expect_true(!is.null(setup) && any(grepl("^include:\\s*false", setup$options)) && !grepl("read_csv", doc, fixed = TRUE),
            label = "The setup chunk runs but stays hidden", message = "Add `#| include: false` to the setup chunk.")
expect_true(is.data.frame(get_object("crew")) && nrow(get_object("crew")) == nrow(truth),
            label = "`crew` holds the whole log", message = "The setup chunk should read `astronauts.csv` into `crew`.")

step(2)
p <- get_object("people")
ok_p <- is.data.frame(p) && nrow(p) == nrow(f) && all(c("sex", "age", "total_missions") %in% names(p))
expect_true(ok_p, label = "`people` has one row per astronaut with `sex`, `age` and `total_missions`",
            message = sprintf("%d rows: `filter(mission_number == 1)`, then `transmute()` or `mutate()` the three columns.", nrow(f)))
if (ok_p) {
  expect_true(isTRUE(all.equal(sort(as.numeric(p$age)), sort(f$age))) &&
                isTRUE(all.equal(sort(as.numeric(p$total_missions)), sort(as.numeric(f$total_number_of_missions)))),
              label = "`age` is age at first flight and `total_missions` the career total",
              message = "`age = year_of_mission - year_of_birth`, `total_missions = total_number_of_missions`.")
}

step(3)
expect_computed(as.character(nrow(f)), label = "The participants sentence gives the number of astronauts, from R",
                message = "Write it with inline code: `` `r nrow(people)` ``.")
expect_computed(as.character(sum(f$sex == "female")), label = "...and the number of women, from R",
                message = "`` `r sum(people$sex == \"female\")` ``.")

step(4)
ab <- get_object("age_by_sex")
ok_ab <- is.data.frame(ab) && nrow(ab) == 2 && all(c("n", "M", "SD") %in% names(ab))
expect_true(ok_ab && isTRUE(all.equal(sort(as.numeric(ab$M)), sort(as.numeric(tapply(f$age, f$sex, mean))))),
            label = "`age_by_sex` has n, M and SD of age for women and men",
            message = "`people |> group_by(sex) |> summarise(n = n(), M = mean(age), SD = sd(age))`.")
expect_true(grepl("Age at First Flight by Sex", doc, fixed = TRUE) && grepl("|", doc, fixed = TRUE) &&
              grepl(formatC(mean(f$age[f$sex == "female"]), format = "f", digits = 2), doc, fixed = TRUE),
            label = "The report shows the table: two decimals and its caption",
            message = "`knitr::kable(age_by_sex, digits = 2, col.names = c(\"Sex\", \"*n*\", \"*M*\", \"*SD*\"), caption = \"Age at First Flight by Sex\")`.")
expect_true(!grepl("kable(", doc, fixed = TRUE) && !grepl("summarise(", doc, fixed = TRUE),
            label = "The report shows no code", message = "Hide chunk code: `knitr::opts_chunk$set(echo = FALSE)` in the setup chunk, or `#| echo: false` in each chunk.")

step(5)
expect_ggplot("age_plot", aes = c(x = "sex", y = "age"))
ap <- get_object("age_plot")
expect_true(inherits(ap, "ggplot") && !is.null(gg_label(ap, "y")) && gg_label(ap, "y") != "age",
            label = "The figure's axes are labelled for a reader",
            message = "`labs(x = \"Sex\", y = \"Age at first flight (years)\")`.")
expect_plot(label = "The figure appears in the report", message = "Print the plot in its chunk: put `age_plot` on a line by itself.")

step(6)
at <- get_object("age_test")
expect_true(inherits(at, "htest") && isTRUE(all.equal(unname(at$statistic), unname(ref_t$statistic))) &&
              isTRUE(all.equal(unname(at$parameter), unname(ref_t$parameter))),
            label = "`age_test` is Welch's t-test of age by sex", message = "`t.test(age ~ sex, data = people)`.")
expect_object("age_d", ref_d, tolerance = 1e-6, label = "`age_d` is Cohen's d (the number)",
              message = "`cohens_d(age ~ sex, data = people)$Cohens_d`.")
expect_apa(doc, ref_t, c(d = ref_d))

step(7)
mc <- get_object("missions_cor")
expect_true(inherits(mc, "htest") && grepl("Spearman", mc$method) && isTRUE(all.equal(unname(mc$estimate), unname(ref_r$estimate))),
            label = "`missions_cor` is Spearman's correlation of age with total missions",
            message = "`cor.test(people$age, people$total_missions, method = \"spearman\", exact = FALSE)`.")
expect_apa(doc, ref_r)

step(8)
prose <- prose_text()
typed <- regmatches(prose, gregexpr("[=<>]\\s*[-−]?[0-9]*\\.?[0-9]+", prose))[[1]]
expect_true(length(typed) == 0, label = "No statistic is typed into the text",
            message = sprintf("These look typed: %s. Write them with inline R so they stay true to the data.",
                              paste(sprintf("\"%s\"", typed), collapse = ", ")))
n_inline <- lengths(regmatches(learner_code(), gregexpr("`r [^`]+`", learner_code())))
expect_true(n_inline >= 8, label = "The numbers in the text come from inline R",
            message = sprintf("The text has %d inline R values; the participants and two results need at least 8.", n_inline))
