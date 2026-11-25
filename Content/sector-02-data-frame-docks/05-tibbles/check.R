expect_called("library", message = "Load the package with `library(tibble)`.")
expect_class("study_tbl", "tbl_df", message = "Convert with `study_tbl <- as_tibble(study)`.")
expect_true(isTRUE(all.equal(as.data.frame(get_object("study_tbl")), get_object("study"),
                             check.attributes = FALSE)),
            label = "`study_tbl` holds the same data as `study`",
            message = "Make `study_tbl` straight from `study` with `as_tibble()`.")
expect_called("glimpse")
expect_class("pilot", "tbl_df", message = "Build `pilot` with `tibble()`.")
p <- get_object("pilot")
expect_true(identical(names(p), c("id", "score", "score_pct")),
            label = "`pilot` has columns id, score, score_pct",
            message = "Name the columns id, score and score_pct, in that order.")
expect_true(isTRUE(all.equal(p$score_pct, c(76, 90, 58, 82))),
            label = "`score_pct` is each score as a percentage",
            message = "Calculate it from `score` inside `tibble()`: `score_pct = score / 50 * 100`.")
