# Checks every sector and level under Content/. Run it with scripts/validate_content.sh.
#
# For each sector: sector.json is valid and its id matches the folder number.
# For each level:  level.json is valid, the files exist, the id is unique, `unlocks`
#                  points at real levels, solution.R passes check.R with no check
#                  errors, and starter.R does NOT pass (otherwise the level is free).
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
lab_kinds <- c("distribution_sculptor", "sampling_machine")
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

sector_dirs <- sort(list.dirs(content_dir, recursive = FALSE))
sector_dirs <- sector_dirs[startsWith(basename(sector_dirs), "sector-")]
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
