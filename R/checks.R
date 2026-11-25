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
# Boss levels (several steps in one script):
#   step(n)                          — the checks that follow belong to step n of the level's
#                                      `steps` list (level.json); the app opens step n + 1 once
#                                      every check of step n passes
#
# APA write-ups:
#   expect_apa(text, test, effect)   — `text` reports `test` in APA style: the statistic with its
#                                      df and two decimals, an exact p without a leading zero
#                                      (p < .001 below .001), and each effect size in `effect`,
#                                      e.g. c(d = 0.42) or c(eta2 = .12). `test` is an htest
#                                      (t.test, cor.test, chisq.test, oneway.test) or a list
#                                      list(stat = "F", df = c(2, 57), value = 4.1, p = .02);
#                                      stat is "t", "F", "r", "rs" or "chi" (chi also takes n).
#                                      Records one check each for the statistic, p and effects.
#   apa_parts(test)                  — what expect_apa expects from `test` (for writing checks)
#
# Documents (levels with "document" in level.json; the code is a Quarto file):
#   document_text()                  — the knitted Markdown (inline `r` values filled in)
#   document_yaml()                  — the YAML header as a list (e.g. document_yaml()$title)
#   document_chunks()                — the R chunks: a list of (label, options, code)
#   prose_text()                     — the source with the YAML, chunks and inline `r` code
#                                      removed: the words the learner typed
#   expect_document(pattern, fixed)  — the knitted document matches a regular expression
#   expect_computed(text)            — `text` (e.g. "1,277") appears in the knitted document
#                                      but wasn't typed in the prose, so R computed it
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
    internal = FALSE,
    step = .ss$step
  )
  invisible(isTRUE(passed))
}

step <- function(n) {
  .ss$step <- as.integer(n)
  invisible(n)
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
  code <- if (isTRUE(.ss$is_document)) .document_r_code() else .ss$code
  parsed <- tryCatch(parse(text = code, keep.source = TRUE), error = function(e) NULL)
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


# --- Documents -------------------------------------------------------------------

document_text <- function() .ss$document %||% ""

document_yaml <- function() .ss$yaml %||% list()

.source_lines <- function() strsplit(.ss$code, "\n", fixed = TRUE)[[1]]

.chunk_fence <- "^\\s*(`{3,})\\s*\\{[rR]([ ,][^}]*)?\\}\\s*$"

document_chunks <- function() {
  lines <- .source_lines()
  chunks <- list()
  i <- 1L
  while (i <= length(lines)) {
    if (grepl(.chunk_fence, lines[i])) {
      header <- sub(.chunk_fence, "\\2", lines[i])
      j <- i + 1L
      while (j <= length(lines) && !grepl("^\\s*`{3,}\\s*$", lines[j])) j <- j + 1L
      body <- if (j > i + 1L) lines[(i + 1L):(j - 1L)] else character()
      opts <- sub("^\\s*#\\|\\s*", "", grep("^\\s*#\\|", body, value = TRUE))
      label <- sub("^\\s*label:\\s*", "", grep("^\\s*label:", opts, value = TRUE))[1]
      if (is.na(label)) label <- trimws(sub(",.*$", "", header))
      chunks[[length(chunks) + 1L]] <- list(label = if (nzchar(label %||% "")) label else NA_character_,
                                            options = c(opts, if (nzchar(trimws(header))) trimws(header)),
                                            code = paste(grep("^\\s*#\\|", body, value = TRUE, invert = TRUE),
                                                         collapse = "\n"))
      i <- j + 1L
    } else {
      i <- i + 1L
    }
  }
  chunks
}

.inline_pattern <- "`r ([^`]+)`"

.document_r_code <- function() {
  chunk_code <- vapply(document_chunks(), function(ch) ch$code, "")
  inline <- regmatches(.ss$code, gregexpr(.inline_pattern, .ss$code))[[1]]
  paste(c(chunk_code, sub("^`r ", "", sub("`$", "", inline))), collapse = "\n")
}

prose_text <- function() {
  lines <- .source_lines()
  if (length(lines) && trimws(lines[1]) == "---") {
    end <- which(trimws(lines[-1]) %in% c("---", "..."))
    if (length(end)) lines <- lines[-seq_len(end[1] + 1L)]
  }
  keep <- rep(TRUE, length(lines))
  inside <- FALSE
  for (i in seq_along(lines)) {
    if (!inside && grepl(.chunk_fence, lines[i])) { inside <- TRUE; keep[i] <- FALSE }
    else if (inside) { keep[i] <- FALSE; if (grepl("^\\s*`{3,}\\s*$", lines[i])) inside <- FALSE }
  }
  gsub(.inline_pattern, "", paste(lines[keep], collapse = "\n"))
}

expect_document <- function(pattern, fixed = FALSE, label = NULL, message = NULL) {
  label <- label %||% sprintf("The report shows \"%s\"", pattern)
  .record(grepl(pattern, document_text(), fixed = fixed), label,
          message %||% "The knitted report doesn't show this yet. Check the Report tab.")
}

expect_computed <- function(text, label = NULL, message = NULL) {
  label <- label %||% sprintf("The report shows %s, computed by R", text)
  shown <- grepl(text, document_text(), fixed = TRUE)
  typed <- grepl(text, prose_text(), fixed = TRUE)
  .record(shown && !typed, label, message %||% if (typed) sprintf(
    "%s is typed into the text. Let R fill it in with inline code, e.g. `` `r nrow(data)` ``, so it updates when the data change.", text)
  else sprintf("The knitted report doesn't show %s yet. Compute it with inline R code.", text))
}

# --- APA write-ups ---------------------------------------------------------------

.apa_symbols <- list(
  t = list(pattern = "t", show = "t"),
  F = list(pattern = "F", show = "F"),
  r = list(pattern = "r", show = "r"),
  rs = list(pattern = "(?:rs|r_s|ρ|rho)", show = "rₛ"),
  chi = list(pattern = "(?:χ²|χ2|χ\\^2|Χ²|X²|X2|X\\^2|chi-square|chi\\^?2)", show = "χ²")
)

.apa_effects <- list(
  d = list(pattern = "d", show = "d", bounded = FALSE),
  g = list(pattern = "g", show = "g", bounded = FALSE),
  eta2 = list(pattern = "(?:η²|η2|η\\^2|ηp²|η²p|ηp2|partial η²|eta-squared|eta\\^?2)", show = "η²", bounded = TRUE),
  omega2 = list(pattern = "(?:ω²|ω2|ω\\^2|omega\\^?2)", show = "ω²", bounded = TRUE),
  R2 = list(pattern = "(?:R²|R2|R\\^2)", show = "R²", bounded = TRUE),
  V = list(pattern = "(?:Cram[eé]r's V|V)", show = "V", bounded = TRUE),
  phi = list(pattern = "(?:φ|phi)", show = "φ", bounded = TRUE),
  r = list(pattern = "r", show = "r", bounded = TRUE)
)

.apa_number <- "[-+]?(?:[0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)"

.apa_clean <- function(text) {
  text <- paste(as.character(unlist(text)), collapse = " ")
  text <- gsub("[*_~]", "", text)                     # *t*, _p_, r~s~ (Markdown italics, subscripts)
  text <- gsub("[−–—]", "-", text)     # minus sign and dashes used as minus
  text <- gsub("[   ]", " ", text)     # non-breaking and thin spaces
  text
}

.decimals <- function(s) if (grepl(".", s, fixed = TRUE)) nchar(sub("^[^.]*\\.", "", s)) else 0L

# Is the written number `s` the value correctly rounded to the decimals it shows?
.rounds_to <- function(s, value) abs(as.numeric(s) - value) <= 10^-.decimals(s) / 2 + 1e-9

.fmt_apa <- function(x, bounded = FALSE, digits = 2) {
  out <- formatC(x, format = "f", digits = digits)
  if (bounded) out <- sub("^(-?)0\\.", "\\1.", out)
  sub("^-", "\u2212", out)   # a true minus sign, as APA typesets it
}

.fmt_df <- function(df) {
  vapply(df, function(x) if (abs(x - round(x)) < 1e-9) format(round(x)) else formatC(x, format = "f", digits = 2), "")
}

apa_parts <- function(test) {
  if (inherits(test, "htest")) {
    stat <- names(test$statistic)
    method <- test$method %||% ""
    p <- test$p.value
    if (grepl("Pearson's product-moment", method)) {
      return(list(stat = "r", df = unname(test$parameter), value = unname(test$estimate), p = p))
    }
    if (grepl("Spearman", method)) {
      return(list(stat = "rs", df = NULL, value = unname(test$estimate), p = p))
    }
    if (identical(stat, "t")) return(list(stat = "t", df = unname(test$parameter), value = unname(test$statistic), p = p))
    if (identical(stat, "F")) return(list(stat = "F", df = unname(test$parameter), value = unname(test$statistic), p = p))
    if (identical(stat, "X-squared")) {
      return(list(stat = "chi", df = unname(test$parameter), value = unname(test$statistic), p = p,
                  n = if (!is.null(test$observed)) sum(test$observed) else NULL))
    }
    stop("expect_apa() doesn't know how to report a ", method)
  }
  if (is.list(test) && !is.null(test$stat)) return(test)
  stop("expect_apa() needs an htest or a list(stat, df, value, p)")
}

expect_apa <- function(text, test, effect = NULL, label = NULL) {
  want <- apa_parts(test)
  sym <- .apa_symbols[[want$stat]]
  bounded_stat <- want$stat %in% c("r", "rs")
  value_shown <- .fmt_apa(if (want$stat == "t") abs(want$value) else want$value, bounded = bounded_stat)
  inside <- c(if (!is.null(want$df)) paste(.fmt_df(want$df), collapse = ", "),
              if (!is.null(want$n)) sprintf("N = %d", as.integer(want$n)))
  shown <- sprintf("*%s*%s = %s", sym$show, if (length(inside)) sprintf("(%s)", paste(inside, collapse = ", ")) else "",
                   if (want$stat == "t" && want$value < 0) paste0("−", value_shown) else value_shown)
  clean <- .apa_clean(text)
  ok_all <- TRUE

  # 1. The statistic, with its df (and N for chi-square)
  stat_label <- label %||% sprintf("The write-up reports %s", shown)
  stat_re <- sprintf("(?:^|[^A-Za-zα-ω])%s\\s*(?:\\(([^)]*)\\))?\\s*=\\s*(%s)", sym$pattern, .apa_number)
  m <- regmatches(clean, regexec(stat_re, clean, perl = TRUE))[[1]]
  problem <- NULL
  after <- clean
  if (!length(m)) {
    problem <- sprintf("Couldn't find the test statistic. Write it as %s.", shown)
  } else {
    after <- substring(clean, regexpr(stat_re, clean, perl = TRUE)[1])
    parts <- if (nzchar(m[2])) trimws(strsplit(m[2], ",", fixed = TRUE)[[1]]) else character()
    n_part <- grep("^N\\s*=", parts, value = TRUE)
    df_parts <- setdiff(parts, n_part)
    value <- m[3]
    num <- as.numeric(value)
    target <- if (want$stat == "t") abs(want$value) else want$value
    if (!is.null(want$df) && length(df_parts) != length(want$df)) {
      problem <- sprintf("Put the degrees of freedom in parentheses: %s.", shown)
    } else if (!is.null(want$df) && !all(mapply(function(s, d) grepl(paste0("^", .apa_number, "$"), s) && .rounds_to(s, d), df_parts, want$df))) {
      problem <- sprintf("The degrees of freedom should be %s (you wrote %s).", paste(.fmt_df(want$df), collapse = ", "),
                         paste(df_parts, collapse = ", "))
    } else if (!is.null(want$n) && (!length(n_part) || as.numeric(sub("^N\\s*=\\s*", "", n_part[1])) != want$n)) {
      problem <- sprintf("APA reports the sample size with chi-square: %s.", shown)
    } else if (!.rounds_to(sub("^-", "", value), abs(target)) || (want$stat != "t" && sign(num) != sign(round(target, 2)) && round(target, 2) != 0)) {
      problem <- sprintf("%s should be %s (you wrote %s).", sym$show, value_shown, value)
    } else if (.decimals(value) != 2) {
      problem <- sprintf("Report %s to two decimals: %s.", sym$show, value_shown)
    } else if (bounded_stat && grepl("^-?0\\.", value)) {
      problem <- sprintf("A correlation can't be bigger than 1, so APA drops the leading zero: %s = %s.", sym$show, value_shown)    } else if (!bounded_stat && grepl("^-?\\.", value)) {
      problem <- sprintf("%s can be bigger than 1, so APA keeps the leading zero: %s = %s.", sym$show, sym$show, value_shown)
    }
  }
  ok_all <- .record(is.null(problem), stat_label, problem) && ok_all

  # 2. p, in APA style
  p_true <- want$p
  p_shown <- if (p_true < .001) "*p* < .001" else sprintf("*p* = %s", .fmt_apa(p_true, bounded = TRUE, digits = 3))
  p_re <- sprintf("(?:^|[^A-Za-z])p\\s*([=<>≤])\\s*(%s)", .apa_number)
  pm <- regmatches(after, regexec(p_re, after, perl = TRUE))[[1]]
  problem <- NULL
  if (!length(pm)) {
    problem <- sprintf("Add the p-value after the statistic: %s.", p_shown)
  } else {
    op <- pm[2]
    pv <- pm[3]
    if (grepl("^0\\.", pv)) {
      problem <- sprintf("Drop the leading zero: a p-value can't be bigger than 1, so APA writes %s.", p_shown)
    } else if (p_true < .001) {
      if (op != "<" || as.numeric(pv) != .001) {
        problem <- if (op == "=" && as.numeric(pv) == 0) "SPSS's .000 means p < .001, so write *p* < .001 (a p-value is never exactly 0)."
                   else "APA reports p-values below .001 as *p* < .001."
      }
    } else if (op != "=") {
      problem <- sprintf("Give the exact p-value, %s, rather than a threshold.", p_shown)
    } else if (!(.decimals(pv) %in% 2:3)) {
      problem <- sprintf("Report p to three decimals (or two): %s.", p_shown)
    } else if (!.rounds_to(pv, p_true)) {
      problem <- sprintf("p should be %s (you wrote %s).", sub("^\\*p\\* = ", "", p_shown), pv)
    }
  }
  ok_all <- .record(is.null(problem), sprintf("The p-value is written APA-style: %s", p_shown), problem) && ok_all

  # 3. Effect sizes
  for (name in names(effect)) {
    es <- .apa_effects[[name]]
    if (is.null(es)) stop("expect_apa() doesn't know the effect size ", name)
    target <- unname(effect[[name]])
    es_value <- .fmt_apa(if (name %in% c("d", "g")) abs(target) else target, bounded = es$bounded)
    es_shown <- sprintf("*%s* = %s", es$show, es_value)
    es_re <- sprintf("(?:^|[^A-Za-zα-ω])%s\\s*=\\s*(%s)", es$pattern, .apa_number)
    em <- regmatches(after, regexec(es_re, after, perl = TRUE))[[1]]
    problem <- NULL
    if (!length(em)) {
      problem <- sprintf("Add the effect size: %s.", es_shown)
    } else {
      v <- em[2]
      if (!.rounds_to(sub("^-", "", v), abs(target))) problem <- sprintf("%s should be %s (you wrote %s).", es$show, es_value, v)
      else if (.decimals(v) != 2) problem <- sprintf("Report %s to two decimals: %s.", es$show, es_value)
      else if (es$bounded && grepl("^-?0\\.", v)) problem <- sprintf("%s can't be bigger than 1, so APA drops the leading zero: %s.", es$show, es_shown)
      else if (!es$bounded && grepl("^-?\\.", v)) problem <- sprintf("%s can be bigger than 1, so APA keeps the leading zero: %s.", es$show, es_shown)
    }
    ok_all <- .record(is.null(problem), sprintf("The effect size is reported: %s", es_shown), problem) && ok_all
  }
  invisible(ok_all)
}
