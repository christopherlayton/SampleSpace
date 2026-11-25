# Sample Space check helpers.
#
# A level's check.R is plain R that calls these helpers. Each call adds one line to
# the checklist the learner sees. Check code runs in an environment whose parent is
# the learner's environment, so learner objects can be used directly, e.g.
#   expect_true(mean_score > 3, label = "`mean_score` is above 3")
#
# Every helper takes:
#   label   — what is being checked (shown in the checklist; a default is generated)
#   message — friendly feedback shown when the check fails (a default is generated)
#
# Helpers:
#   expect_object(name, value, tolerance, check_attributes) — object exists (and equals value)
#   expect_class(name, class)        — object inherits from class
#   expect_equal(actual, expected)   — any value equals expected
#   expect_true(condition)           — any condition is TRUE
#   expect_called(fn)                — the code calls fn(), e.g. "mean" or "dplyr::filter"
#   expect_not_called(fn)            — the code does not call fn()
#   expect_output(pattern, fixed)    — console output matches a regular expression
#   expect_printed(value)            — the console shows value printed in full, e.g. [1] 152
#   expect_plot(n = 1)               — at least n plots were drawn
#   expect_no_error()                — the code ran without an error
#   expect_ggplot(name, geom, aes)   — object is a ggplot with that layer, e.g. geom = "boxplot",
#                                      aes = c(x = "decade", y = "hours_mission"); a mapped
#                                      expression counts if it uses the variable (factor(decade))
#   gg_label(plot, which)            — a plot's axis/legend/title label, e.g. gg_label(p, "x")
#   get_object(name)                 — the learner's object, or NULL if it does not exist
#   learner_code()                   — the learner's code as one string
#
# This file is sourced by runner.R into an environment that also holds `.ss`, the run state.

.short <- function(x, width = 60) {
  text <- tryCatch(
    paste(utils::capture.output(print(x)), collapse = " "),
    error = function(e) paste(class(x), collapse = "/")
  )
  text <- gsub("\\s+", " ", trimws(text))
  if (nchar(text) > width) paste0(substr(text, 1, width - 1), "…") else text
}

.type_name <- function(x) {
  if (is.factor(x)) return("factor")
  if (is.data.frame(x)) return("data frame")
  if (is.matrix(x)) return("matrix")
  if (is.list(x)) return("list")
  if (is.function(x)) return("function")
  typeof(x)
}

.record <- function(passed, label, message) {
  .ss$checks[[length(.ss$checks) + 1L]] <- list(
    passed = isTRUE(passed),
    label = label,
    message = if (isTRUE(passed)) NULL else message,
    internal = FALSE
  )
  invisible(isTRUE(passed))
}

.same <- function(actual, expected, tolerance, check_attributes) {
  isTRUE(all.equal(expected, actual, tolerance = tolerance,
                   check.attributes = check_attributes))
}

.mismatch_message <- function(what, actual, expected) {
  type_a <- .type_name(actual)
  type_e <- .type_name(expected)
  if (type_a != type_e && !(is.numeric(actual) && is.numeric(expected))) {
    return(sprintf("%s is a %s, but a %s was expected.", what, type_a, type_e))
  }
  if (length(actual) != length(expected)) {
    return(sprintf("%s has %d element%s, but %d %s expected.", what, length(actual),
                   if (length(actual) == 1) "" else "s", length(expected),
                   if (length(expected) == 1) "was" else "were"))
  }
  sprintf("%s isn't quite right yet. It is currently: %s", what, .short(actual))
}

get_object <- function(name) {
  if (exists(name, envir = .ss$learner, inherits = FALSE)) {
    get(name, envir = .ss$learner, inherits = FALSE)
  } else {
    NULL
  }
}

learner_code <- function() .ss$code

expect_object <- function(name, value, tolerance = 1e-6, check_attributes = FALSE,
                          label = NULL, message = NULL) {
  has_value <- !missing(value)
  if (is.null(label)) {
    label <- if (has_value) sprintf("`%s` has the right value", name) else sprintf("`%s` exists", name)
  }
  if (!exists(name, envir = .ss$learner, inherits = FALSE)) {
    return(.record(FALSE, label, message %||% sprintf(
      "There is no object called `%s` yet. Create it with `%s <- ...` (R names are case-sensitive).",
      name, name)))
  }
  if (!has_value) return(.record(TRUE, label, NULL))
  actual <- get(name, envir = .ss$learner, inherits = FALSE)
  ok <- .same(actual, value, tolerance, check_attributes)
  .record(ok, label, message %||% .mismatch_message(sprintf("`%s`", name), actual, value))
}

expect_class <- function(name, class, label = NULL, message = NULL) {
  label <- label %||% sprintf("`%s` is a %s", name, class)
  if (!exists(name, envir = .ss$learner, inherits = FALSE)) {
    return(.record(FALSE, label, message %||% sprintf("There is no object called `%s` yet.", name)))
  }
  actual <- get(name, envir = .ss$learner, inherits = FALSE)
  .record(inherits(actual, class), label, message %||% sprintf(
    "`%s` should be a %s, but it is a %s.", name, class, paste(class(actual), collapse = "/")))
}

expect_equal <- function(actual, expected, tolerance = 1e-6, check_attributes = FALSE,
                         label = NULL, message = NULL) {
  label <- label %||% sprintf("`%s` has the expected value", deparse1(substitute(actual)))
  ok <- .same(actual, expected, tolerance, check_attributes)
  .record(ok, label, message %||% .mismatch_message("The result", actual, expected))
}

expect_true <- function(condition, label = NULL, message = NULL) {
  label <- label %||% sprintf("`%s`", deparse1(substitute(condition)))
  .record(isTRUE(condition), label, message %||% "This condition isn't met yet.")
}

.called_functions <- function() {
  if (!is.null(.ss$calls)) return(.ss$calls)
  parsed <- tryCatch(parse(text = .ss$code, keep.source = TRUE), error = function(e) NULL)
  if (is.null(parsed)) return(character())
  data <- utils::getParseData(parsed)
  data <- data[data$terminal, c("token", "text")]
  calls <- character()
  for (i in which(data$token == "SYMBOL_FUNCTION_CALL")) {
    fn <- data$text[i]
    calls <- c(calls, fn)
    if (i >= 3 && data$token[i - 1] %in% c("NS_GET", "NS_GET_INT")) {
      calls <- c(calls, paste0(data$text[i - 2], "::", fn))
    }
  }
  .ss$calls <- unique(calls)
  .ss$calls
}

expect_called <- function(fn, label = NULL, message = NULL) {
  label <- label %||% sprintf("Uses `%s()`", fn)
  .record(fn %in% .called_functions(), label,
          message %||% sprintf("Try using `%s()` for this one.", fn))
}

expect_not_called <- function(fn, label = NULL, message = NULL) {
  label <- label %||% sprintf("Doesn't use `%s()`", fn)
  .record(!(fn %in% .called_functions()), label,
          message %||% sprintf("Try solving this without `%s()`.", fn))
}

expect_output <- function(pattern, fixed = FALSE, label = NULL, message = NULL) {
  label <- label %||% sprintf("Output shows \"%s\"", pattern)
  .record(grepl(pattern, .ss$output_text(), fixed = fixed), label,
          message %||% "The console output doesn't show what was expected yet.")
}

expect_printed <- function(value, label = NULL, message = NULL) {
  printed <- paste(utils::capture.output(print(value)), collapse = "\n")
  label <- label %||% sprintf("Prints %s", printed)
  # Match whole lines, so [1] 15 doesn't count as [1] 152.
  ok <- grepl(paste0("\n", printed, "\n"), paste0("\n", .ss$output_text(), "\n"), fixed = TRUE)
  .record(ok, label, message %||% sprintf(
    "The console doesn't show %s yet. A value is printed when it is on a line by itself.", printed))
}

expect_plot <- function(n = 1, label = NULL, message = NULL) {
  label <- label %||% if (n == 1) "Draws a plot" else sprintf("Draws %d plots", n)
  .record(length(.ss$plots) >= n, label,
          message %||% "No plot was drawn. Make sure your plotting code runs (a ggplot needs to be printed).")
}

expect_no_error <- function(label = "Runs without an error", message = NULL) {
  .record(.ss$status == "ok", label,
          message %||% "Your code stopped with an error. Fix that first; the console shows where.")
}

# geom_*() names → how the layer looks inside a ggplot (geom class, and stat where two share a geom).
.gg_geoms <- list(
  histogram = c("GeomBar", "StatBin"), bar = c("GeomBar", "StatCount"), col = c("GeomCol", NA),
  boxplot = c("GeomBoxplot", NA), point = c("GeomPoint", NA), jitter = c("GeomPoint", NA),
  errorbar = c("GeomErrorbar", NA), smooth = c("GeomSmooth", NA), line = c("GeomLine", NA),
  density = c("GeomDensity", NA), violin = c("GeomViolin", NA), hline = c("GeomHline", NA),
  vline = c("GeomVline", NA), pointrange = c("GeomPointrange", NA)
)

.gg_has_geom <- function(layer, geom) {
  want <- .gg_geoms[[geom]]
  if (is.null(want)) return(inherits(layer$geom, paste0("Geom", tools::toTitleCase(geom))))
  if (geom == "histogram" || geom == "bar") {
    return(class(layer$geom)[1] == "GeomBar" && inherits(layer$stat, want[2]))
  }
  class(layer$geom)[1] == want[1]
}

# Does this layer (with the plot's own mapping underneath) map aesthetic `aes` to variable `var`?
.gg_maps <- function(plot, layer, aes, var) {
  mapping <- utils::modifyList(as.list(plot$mapping), as.list(if (is.null(layer)) list() else layer$mapping))
  m <- mapping[[aes]] %||% if (aes == "colour") mapping[["color"]] else NULL
  if (is.null(m)) return(FALSE)
  expr <- rlang::quo_get_expr(m)
  identical(rlang::as_label(m), var) || var %in% all.vars(expr)
}

expect_ggplot <- function(name, geom = NULL, aes = NULL, label = NULL, message = NULL) {
  parts <- c(if (!is.null(geom)) sprintf("`geom_%s()`", geom),
             if (length(aes)) paste(sprintf("%s = %s", names(aes), aes), collapse = ", "))
  label <- label %||% sprintf("`%s` is a ggplot%s", name,
                              if (length(parts)) paste0(" with ", paste(parts, collapse = " and ")) else "")
  p <- get_object(name)
  if (is.null(p)) return(.record(FALSE, label, message %||% sprintf(
    "There is no object called `%s` yet. Store the plot: `%s <- ggplot(...) + ...`.", name, name)))
  if (!inherits(p, "ggplot")) return(.record(FALSE, label, message %||% sprintf(
    "`%s` isn't a ggplot. Build it with `ggplot(data, aes(...))` and add layers with `+`.", name)))
  layers <- if (is.null(geom)) list(NULL) else Filter(function(l) .gg_has_geom(l, geom), p$layers)
  if (!length(layers)) return(.record(FALSE, label, message %||% sprintf(
    "`%s` has no `geom_%s()` layer yet. Add one with `+ geom_%s()`.", name, geom, geom)))
  for (a in names(aes)) {
    if (!any(vapply(layers, function(l) .gg_maps(p, l, a, aes[[a]]), TRUE))) {
      return(.record(FALSE, label, message %||% sprintf(
        "Map `%s = %s` inside `aes()`. Settings outside `aes()` (like `fill = \"blue\"`) apply one fixed value instead.",
        a, aes[[a]])))
    }
  }
  .record(TRUE, label, NULL)
}

gg_label <- function(plot, which) {
  if (!inherits(plot, "ggplot")) return(NULL)
  labs <- if (exists("get_labs", asNamespace("ggplot2"))) ggplot2::get_labs(plot) else plot$labels
  value <- labs[[which]]
  if (is.null(value) || is.function(value) || inherits(value, "waiver")) NULL else as.character(value)
}

