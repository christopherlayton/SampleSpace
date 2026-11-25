answered <- c("Not at all", "A little", "Moderately", "Very", "Extremely")
# The five answered categories, by name, so a dropped "No answer" level is fine either way.
pick <- function(x) {
  if (is.null(x) || is.null(names(x)) || !all(answered %in% names(x))) return(NULL)
  as.numeric(x[answered])
}
expect_true(is.factor(get_object("teach_f")$method),
            label = "`teach_f` has the value labels",
            message = "Convert the labels with `teach_f <- as_factor(teach)`.")
counts <- get_object("method_counts")
expect_true(inherits(counts, "table") && identical(as.vector(counts), c(15L, 15L)) &&
              identical(names(counts), c("Lecture", "Active learning")),
            label = "`method_counts` matches the Frequency column",
            message = "Use `table(teach_f$method)` so the counts are labelled Lecture and Active learning.")
expect_object("n_missing", 2,
              message = "SPSS lists 2 missing. Count the NAs: `sum(is.na(teach_f$anxiety))`.")
pct <- pick(get_object("anxiety_pct"))
expect_true(!is.null(pct) && isTRUE(all.equal(pct, c(23.3, 3.3, 20.0, 26.7, 20.0))),
            label = "`anxiety_pct` matches the Percent column",
            message = paste("Percent divides by all 30 cases, missing included:",
                            "`round(100 * table(teach_f$anxiety) / nrow(teach_f), 1)`."))
valid <- pick(get_object("anxiety_valid"))
expect_true(!is.null(valid) && isTRUE(all.equal(valid, c(25.0, 3.6, 21.4, 28.6, 21.4))),
            label = "`anxiety_valid` matches the Valid Percent column",
            message = paste("Valid Percent divides by the 28 answered cases:",
                            "`round(100 * prop.table(table(teach_f$anxiety)), 1)`. Did you round to 1 decimal?"))
