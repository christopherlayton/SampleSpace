# Checks every sector and level under Content/. Run it with scripts/validate_content.sh.
#
# For each sector: sector.json is valid and its id matches the folder number.
# For each level:  level.json is valid, the files exist, the id is unique, `unlocks`
#                  points at real levels, solution.R passes check.R with no check
#                  errors, and starter.R does NOT pass (otherwise the level is free).
# Quiz levels (briefing, predict): no R files needed; every question has a prompt, at
#                  least two choices and a valid 0-based answer; Predict questions have code,
#                  which must run, and (unless "match_output": false) R's printed output must
#                  match the right choice and no other choice. ("run": false shows code without
#                  running it.)
# SPSS Translate:  an "spss" object with a menu path and output tables whose rows have as
#                  many cells as there are columns.
# Review cards:    a sector's optional review.json (Review Nebula, see Models/Review.swift):
#                  unique card ids, each tied to a level in that sector, a known type; concept
#                  cards have choices and a valid answer; fill cards have one ___ blank and
#                  answers, and the code parses as R with each answer filled in; which_test
#                  cards use the test keys below.
#
# Usage: Rscript validate_content.R <repo root> [level id or folder name filter]

args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(args[1])
filter <- if (length(args) >= 2) args[2] else NULL

content_dir <- file.path(root, "Content")
runner <- file.path(root, "R", "runner.R")
rscript <- file.path(R.home("bin"), "Rscript")

level_types <- c("briefing", "code", "predict", "debug", "spss_translate", "lab", "boss")
level_files <- c("level.json", "lesson.md", "starter.R", "solution.R", "check.R")
quiz_files <- c("level.json", "lesson.md")
quiz_types <- c("briefing", "predict")
sector_keys <- c("id", "name", "r_skills", "stats_concepts", "hue", "map_position", "planet_size",
                 "briefing", "log")  # story fields: see STORY.md
level_keys <- c("id", "title", "type", "xp")

problems <- character()
problem <- function(where, text) {
  problems <<- c(problems, sprintf("%s: %s", where, text))
  cat(sprintf("  ✗ %s\n", text))
}

read_json <- function(path, where) {
  tryCatch(jsonlite::fromJSON(path, simplifyVector = TRUE),
           error = function(e) { problem(where, paste("invalid JSON:", conditionMessage(e))); NULL })
}

read_text <- function(path) paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# Runs code through the real runner, the same way the app does.
run_job <- function(level_dir, code, checks, meta) {
  out <- tempfile("ss-validate-")
  dir.create(out)
  on.exit(unlink(out, recursive = TRUE))
  setup_path <- file.path(level_dir, "setup.R")
  job <- list(code = code, checks = checks, output_dir = out, data_dir = level_dir,
              time_limit = meta$time_limit %||% 10, seed = meta$seed,
              setup = if (file.exists(setup_path)) read_text(setup_path) else NULL)
  job <- job[!vapply(job, is.null, TRUE)]
  job_path <- file.path(out, "job.json")
  jsonlite::write_json(job, job_path, auto_unbox = TRUE, digits = NA)
  log <- suppressWarnings(system2(rscript, c("--no-init-file", shQuote(runner), shQuote(job_path)),
                                  stdout = TRUE, stderr = TRUE))
  result_path <- file.path(out, "result.json")
  if (!file.exists(result_path)) {
    return(list(status = "runner_error", passed = FALSE, checks = list(),
                console = list(list(type = "error", text = paste(log, collapse = "\n")))))
  }
  jsonlite::fromJSON(result_path, simplifyVector = FALSE)
}

describe_failure <- function(result) {
  lines <- character()
  for (entry in result$console) {
    if (entry$type == "error") lines <- c(lines, paste("R error:", entry$text))
  }
  for (check in result$checks) {
    if (!isTRUE(check$passed)) {
      lines <- c(lines, sprintf("%s%s — %s", if (isTRUE(check$internal)) "[check error] " else "",
                                check$label, check$message %||% ""))
    }
  }
  paste0("      ", lines, collapse = "\n")
}

# Lab levels need a `lab` object: a known kind and goals, each with text and conditions.
# (Reading names are checked against each instrument by the Swift tests.)
lab_kinds <- c("distribution_sculptor", "sampling_machine", "ci_rain", "p_value_courtroom", "power_reactor",
               "correlation_drag", "least_squares")
check_lab <- function(lab, where) {
  if (is.null(lab)) return(problem(where, "a lab level needs a \"lab\" object"))
  if (!(lab$kind %||% "") %in% lab_kinds) problem(where, sprintf("unknown lab kind \"%s\"", lab$kind %||% ""))
  goals <- lab$goals
  if (!is.data.frame(goals) || nrow(goals) == 0) return(problem(where, "lab has no goals"))
  for (i in seq_len(nrow(goals))) {
    when <- goals$when[[i]]
    if (!nzchar(goals$text[i] %||% "")) problem(where, sprintf("lab goal %d has no text", i))
    if (!is.data.frame(when) || nrow(when) == 0 || !"reading" %in% names(when)) {
      problem(where, sprintf("lab goal %d needs \"when\" conditions with a \"reading\"", i))
    }
  }
}

# What the console shows for a run, as the app prints it (output, warnings and errors).
console_text <- function(result) {
  lines <- vapply(result$console, function(e) {
    switch(e$type,
      output = e$text,
      warning = if (is.null(e$call)) paste("Warning:", e$text) else sprintf("Warning in %s: %s", e$call, e$text),
      error = if (is.null(e$call)) paste("Error:", e$text) else sprintf("Error in %s: %s", e$call, e$text),
      "")
  }, "")
  paste(lines[nzchar(lines)], collapse = "\n")
}
squash <- function(x) gsub("\\s+", " ", trimws(x))

check_quiz <- function(raw, meta, level_dir, where) {
  quiz <- raw$quiz
  if (!is.list(quiz) || length(quiz) == 0) return(problem(where, sprintf("a %s level needs a \"quiz\" list", meta$type)))
  for (i in seq_along(quiz)) {
    q <- quiz[[i]]
    tag <- sprintf("question %d", i)
    if (!nzchar(q$prompt %||% "")) problem(where, paste(tag, "has no prompt"))
    choices <- unlist(q$choices)
    if (length(choices) < 2) { problem(where, paste(tag, "needs at least two choices")); next }
    if (anyDuplicated(choices)) problem(where, paste(tag, "has duplicate choices"))
    answer <- q$answer
    if (!is.numeric(answer) || answer < 0 || answer >= length(choices)) {
      problem(where, sprintf("%s: answer %s isn't a 0-based index into its %d choices", tag, answer %||% "?", length(choices)))
      next
    }
    if (identical(meta$type, "predict") && is.null(q$code)) problem(where, paste(tag, "needs code to predict"))
    if (is.null(q$code) || isFALSE(q$run)) next
    result <- run_job(level_dir, q$code, NULL, meta)
    shown <- console_text(result)
    if (identical(result$status, "runner_error")) {
      problem(where, sprintf("%s: the code couldn't run\n      %s", tag, shown))
    } else if (!isFALSE(q$match_output)) {
      matches <- which(squash(choices) == squash(shown))
      if (!(answer + 1) %in% matches) {
        problem(where, sprintf("%s: R prints\n        %s\n      but the right choice is\n        %s",
                               tag, gsub("\n", "\n        ", shown), choices[answer + 1]))
      } else if (length(matches) > 1) {
        problem(where, paste(tag, "has more than one choice matching R's output"))
      }
    }
  }
}

check_spss <- function(spss, where) {
  if (is.null(spss)) return(problem(where, "an SPSS Translate level needs an \"spss\" object"))
  if (length(spss$menu) == 0) problem(where, "spss.menu is empty")
  if (length(spss$output) == 0) problem(where, "spss.output has no tables")
  for (t in spss$output) {
    n <- length(t$columns)
    if (!nzchar(t$title %||% "")) problem(where, "an SPSS table has no title")
    widths <- vapply(t$rows, length, 1L)
    if (any(widths != n)) problem(where, sprintf("SPSS table \"%s\": rows need %d cells", t$title %||% "?", n))
    if (!is.null(t$groups) && sum(vapply(t$groups, function(g) g$span, 1)) != n) {
      problem(where, sprintf("SPSS table \"%s\": header groups must span %d columns", t$title %||% "?", n))
    }
  }
}

sector_dirs <- sort(list.dirs(content_dir, recursive = FALSE))
sector_dirs <- sector_dirs[startsWith(basename(sector_dirs), "sector-")]
stat_tests <- c("one_sample_t", "independent_t", "paired_t", "one_way_anova", "factorial_anova",
                "repeated_measures_anova", "chi_square", "correlation", "regression")  # StatTest in Swift
cards_seen <- list()   # review card id -> sector

check_review <- function(path, level_ids, where) {
  review <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE),
                     error = function(e) { problem(where, paste("review.json: invalid JSON:", conditionMessage(e))); NULL })
  if (is.null(review)) return(0L)
  if (!is.list(review$cards) || !length(review$cards)) {
    problem(where, "review.json needs a non-empty \"cards\" list")
    return(0L)
  }
  for (card in review$cards) {
    id <- card$id %||% "(no id)"
    bad <- function(text) problem(where, sprintf("review card %s: %s", id, text))
    if (is.null(card$id)) bad("needs an id")
    else if (!is.null(cards_seen[[card$id]])) bad(sprintf("id also used in %s", cards_seen[[card$id]]))
    else cards_seen[[card$id]] <<- where
    if (!isTRUE(card$level %in% level_ids)) bad(sprintf("level \"%s\" isn't in this sector", card$level %||% ""))
    if (!is.character(card$prompt) || !nzchar(card$prompt)) bad("needs a prompt")
    type <- card$type %||% ""
    if (type == "concept") {
      n <- length(card$choices)
      if (n < 2) bad("needs at least two choices")
      if (!is.numeric(card$answer) || card$answer < 0 || card$answer >= n) bad("answer must be a 0-based choice index")
    } else if (type == "fill") {
      code <- card$code %||% ""
      if (lengths(regmatches(code, gregexpr("___", code, fixed = TRUE))) != 1) bad("code needs exactly one ___ blank")
      if (!length(card$answers)) bad("needs accepted answers")
      for (answer in card$answers) {
        filled <- sub("___", answer, code, fixed = TRUE)
        ok <- tryCatch({ parse(text = filled); TRUE }, error = function(e) FALSE)
        if (!ok) bad(sprintf("filled with \"%s\" the code doesn't parse as R", answer))
      }
    } else if (type == "which_test") {
      options <- unlist(card$options %||% list("one_sample_t", "independent_t", "paired_t",
                                                   "one_way_anova", "chi_square", "correlation"))
      unknown <- setdiff(c(options, card$answer), stat_tests)
      if (length(unknown)) bad(paste("unknown test key:", paste(unknown, collapse = ", ")))
      if (!isTRUE(card$answer %in% options)) bad("answer must be one of the options")
    } else {
      bad(sprintf("unknown type \"%s\" (use concept, fill or which_test)", type))
    }
  }
  length(review$cards)
}

levels_seen <- list()  # id -> where
all_unlocks <- list()
n_levels <- 0L
sector_ids <- integer()

for (sector_dir in sector_dirs) {
  sector_name <- basename(sector_dir)
  cat(sprintf("%s\n", sector_name))
  sector_json <- file.path(sector_dir, "sector.json")
  if (!file.exists(sector_json)) {
    problem(sector_name, "sector.json is missing")
    next
  }
  sector <- read_json(sector_json, sector_name)
  if (!is.null(sector)) {
    missing <- setdiff(sector_keys, names(sector))
    if (length(missing)) problem(sector_name, paste("sector.json is missing:", paste(missing, collapse = ", ")))
    folder_number <- suppressWarnings(as.integer(sub("^sector-(\\d+)-.*$", "\\1", sector_name)))
    if (!is.null(sector$id) && !identical(as.integer(sector$id), folder_number)) {
      problem(sector_name, sprintf("id %s doesn't match the folder number %s", sector$id, folder_number))
    }
    if (!is.null(sector$id) && sector$id %in% sector_ids) problem(sector_name, "duplicate sector id")
    sector_ids <- c(sector_ids, sector$id)
  }

  level_dirs <- sort(list.dirs(sector_dir, recursive = FALSE))
  level_dirs <- level_dirs[file.exists(file.path(level_dirs, "level.json"))]
  for (level_dir in level_dirs) {
    where <- file.path(sector_name, basename(level_dir))
    meta <- read_json(file.path(level_dir, "level.json"), where)
    if (is.null(meta)) next
    if (!is.null(filter) && !grepl(filter, meta$id %||% "", fixed = TRUE) &&
        !grepl(filter, where, fixed = TRUE)) next
    n_levels <- n_levels + 1L
    problems_before <- length(problems)
    cat(sprintf("  %s (%s)\n", basename(level_dir), meta$id %||% "no id"))

    missing <- setdiff(level_keys, names(meta))
    if (length(missing)) problem(where, paste("level.json is missing:", paste(missing, collapse = ", ")))
    if (!is.null(meta$type) && !(meta$type %in% level_types)) {
      problem(where, sprintf("unknown type \"%s\"", meta$type))
    }
    if (!is.null(meta$id)) {
      if (!is.null(levels_seen[[meta$id]])) {
        problem(where, sprintf("id \"%s\" is also used by %s", meta$id, levels_seen[[meta$id]]))
      }
      levels_seen[[meta$id]] <- where
      if (!is.null(meta$unlocks)) all_unlocks[[where]] <- meta$unlocks
    }
    if (!is.null(meta$xp) && (!is.numeric(meta$xp) || meta$xp <= 0)) problem(where, "xp must be a positive number")
    if (!is.null(meta$hints) && !is.character(meta$hints)) problem(where, "hints must be a list of strings")
    if (identical(meta$type, "lab")) check_lab(meta$lab, where)
    raw <- jsonlite::fromJSON(file.path(level_dir, "level.json"), simplifyVector = FALSE)
    if (identical(meta$type, "spss_translate")) check_spss(raw$spss, where)

    if (isTRUE(meta$type %in% quiz_types)) {
      missing_files <- quiz_files[!file.exists(file.path(level_dir, quiz_files))]
      if (length(missing_files)) problem(where, paste("missing files:", paste(missing_files, collapse = ", ")))
      check_quiz(raw, meta, level_dir, where)
      if (length(problems) == problems_before) {
        cat(sprintf("  ✓ %d quiz questions are consistent\n", length(raw$quiz)))
      }
      next
    }

    missing_files <- level_files[!file.exists(file.path(level_dir, level_files))]
    if (length(missing_files)) {
      problem(where, paste("missing files:", paste(missing_files, collapse = ", ")))
      next
    }
    if (!nzchar(trimws(read_text(file.path(level_dir, "lesson.md"))))) problem(where, "lesson.md is empty")
    checks <- read_text(file.path(level_dir, "check.R"))
    if (!nzchar(trimws(checks))) {
      problem(where, "check.R is empty")
      next
    }

    solution <- run_job(level_dir, read_text(file.path(level_dir, "solution.R")), checks, meta)
    if (!isTRUE(solution$passed) || any(vapply(solution$checks, function(c) isTRUE(c$internal), TRUE))) {
      problem(where, sprintf("solution.R doesn't pass its checks (status: %s)\n%s",
                             solution$status, describe_failure(solution)))
    } else if (length(solution$checks) == 0) {
      problem(where, "check.R ran but recorded no checks")
    }

    starter <- run_job(level_dir, read_text(file.path(level_dir, "starter.R")), checks, meta)
    if (isTRUE(starter$passed)) problem(where, "starter.R already passes the checks")

    if (length(problems) == problems_before) {
      cat(sprintf("  ✓ solution passes %d checks; starter doesn't pass\n", length(solution$checks)))
    }
  }

  review_path <- file.path(sector_dir, "review.json")
  if (file.exists(review_path)) {
    ids <- vapply(level_dirs, function(d) {
      tryCatch(jsonlite::fromJSON(file.path(d, "level.json"))$id %||% "", error = function(e) "")
    }, "")
    problems_before <- length(problems)
    n_cards <- check_review(review_path, ids, file.path(sector_name, "review.json"))
    if (length(problems) == problems_before) cat(sprintf("  ✓ review.json: %d cards\n", n_cards))
  }
}

for (where in names(all_unlocks)) {
  unknown <- setdiff(all_unlocks[[where]], names(levels_seen))
  if (length(unknown)) {
    problems <- c(problems, sprintf("%s: unlocks unknown level(s): %s", where, paste(unknown, collapse = ", ")))
  }
}

cat("\n")
if (length(problems)) {
  cat(sprintf("%d problem%s found:\n", length(problems), if (length(problems) == 1) "" else "s"))
  cat(paste0("- ", problems, collapse = "\n"), "\n")
  quit(status = 1)
}
cat(sprintf("All good: %d sector%s, %d level%s checked.\n", length(sector_dirs),
            if (length(sector_dirs) == 1) "" else "s", n_levels, if (n_levels == 1) "" else "s"))
