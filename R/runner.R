# Sample Space R runner.
#
# Usage: Rscript --no-init-file runner.R job.json
#
# job.json fields (only `code` and `output_dir` are required):
#   code        learner's R code
#   output_dir  where result.json and plot-NNN.png files are written (must exist)
#   checks      R code calling the helpers in checks.R
#   setup       R code run silently in the learner's environment first (e.g. load data)
#   seed        integer passed to set.seed() just before the learner's code
#   time_limit  seconds the learner's code may run (default 10)
#   data_dir    folder whose data files are copied into output_dir, the learner's working
#               directory (level files — *.R, *.md, *.qmd, *.json — are skipped)
#   width       console width (default 80)
#   document    a file name such as "report.qmd": the code is then a Quarto / R Markdown
#               document, knitted with knitr in the learner's environment (so checks can
#               still see its objects) instead of being run line by line
#
# result.json fields:
#   status   "ok" | "error" | "parse_error" | "timeout" | "runner_error"
#   console  list of {type: input|output|message|warning|error, text, call}
#   plots    file names of plots drawn, in order
#   checks   list of {passed, label, message, internal}
#   passed   TRUE when status is "ok" and every check passed
#   duration seconds spent in the learner's code
#   document for documents: the knitted Markdown, without its YAML header; each figure is
#            replaced by a line {{plot:N}} (N = position in `plots`)
#   title    for documents: the title from the YAML header
#
# Everything lives inside local() so the learner's global environment stays clean.

local({
  max_output_chars <- 200000L
  check_time_limit <- 10

  job_path <- commandArgs(trailingOnly = TRUE)[1]
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]
  runner_dir <- dirname(normalizePath(sub("^--file=", "", file_arg)))

  job <- jsonlite::fromJSON(job_path, simplifyVector = TRUE)
  out_dir <- normalizePath(job$output_dir)
  time_limit <- job$time_limit %||% 10

  # --- Run state, shared with the check helpers -------------------------------
  .ss <- new.env()
  .ss$code <- job$code %||% ""
  .ss$console <- list()
  .ss$checks <- list()
  .ss$plots <- character()
  .ss$status <- "ok"
  .ss$output_chars <- 0L
  .ss$truncated <- FALSE
  .ss$duration <- 0
  .ss$step <- NULL         # set by step() in check.R (Boss levels group checks by step)
  .ss$document <- NULL     # knitted Markdown body, for documents
  .ss$yaml <- NULL         # parsed YAML header, for documents

  add <- function(type, text, call = NULL) {
    if (.ss$truncated) return(invisible())
    .ss$output_chars <- .ss$output_chars + nchar(text, type = "chars")
    if (.ss$output_chars > max_output_chars) {
      .ss$truncated <- TRUE
      type <- "message"
      text <- "[Output was too long, so the rest was cut off.]"
      call <- NULL
    }
    .ss$console[[length(.ss$console) + 1L]] <- list(type = type, text = text, call = call)
    invisible()
  }

  .ss$output_text <- function() {
    texts <- vapply(.ss$console, function(e) if (e$type == "output") e$text else "", "")
    paste(texts, collapse = "\n")
  }

  # Calls that only point at this harness are hidden from the learner.
  internal_calls <- c("eval(expr, env)", "withVisible(eval(expr, env))")
  call_text <- function(cond) {
    call <- conditionCall(cond)
    if (is.null(call)) return(NULL)
    text <- paste(deparse(call, width.cutoff = 80L, nlines = 2L), collapse = " ")
    if (text %in% internal_calls) NULL else text
  }

  is_timeout <- function(e) grepl("reached (session )?elapsed time limit", conditionMessage(e))

  # --- Evaluate one top-level expression, like the R console does -------------
  eval_one <- function(expr, env) {
    captured <- character()
    con <- textConnection("captured", "w", local = TRUE)
    sinks <- sink.number()
    sink(con)
    emitted <- 0L
    flush <- function(final = FALSE) {
      lines <- if (final) captured else textConnectionValue(con)
      if (length(lines) > emitted) {
        add("output", paste(lines[(emitted + 1L):length(lines)], collapse = "\n"))
        emitted <<- length(lines)
      }
    }
    ok <- TRUE
    tryCatch(
      withCallingHandlers(
        {
          res <- withVisible(eval(expr, env))
          if (res$visible) {
            if (isS4(res$value)) methods::show(res$value) else print(res$value)
          }
        },
        warning = function(w) {
          flush()
          add("warning", conditionMessage(w), call_text(w))
          invokeRestart("muffleWarning")
        },
        message = function(m) {
          flush()
          add("message", sub("\n$", "", conditionMessage(m)))
          invokeRestart("muffleMessage")
        }
      ),
      error = function(e) {
        ok <<- FALSE
        setTimeLimit()
        flush()
        if (is_timeout(e)) {
          .ss$status <- "timeout"
          add("error", sprintf(
            "Your code ran for more than %s second%s, so it was stopped. Look for a loop that never ends.",
            format(time_limit), if (time_limit == 1) "" else "s"))
        } else {
          .ss$status <- "error"
          add("error", conditionMessage(e), call_text(e))
        }
      }
    )
    while (sink.number() > sinks) sink()
    close(con)
    flush(final = TRUE)
    ok
  }

  write_result <- function() {
    passed <- .ss$status == "ok" &&
      all(vapply(.ss$checks, function(c) isTRUE(c$passed), TRUE))
    result <- list(
      status = .ss$status,
      console = .ss$console,
      plots = as.list(.ss$plots),
      checks = .ss$checks,
      passed = passed,
      duration = round(.ss$duration, 3)
    )
    if (!is.null(.ss$document)) {
      result$document <- .ss$document
      result$title <- if (is.character(.ss$yaml$title)) .ss$yaml$title[1] else NULL
    }
    jsonlite::write_json(result, file.path(out_dir, "result.json"),
                         auto_unbox = TRUE, null = "null", digits = NA)
  }

  run <- function() {
    options(width = job$width %||% 80, warn = 0, digits = 7, help_type = "text")
    Sys.setenv(LANGUAGE = "en")

    # Help pages (?mean) normally go to a pager outside R's output; print them into the
    # console instead, without the backspace-underline formatting R uses for terminals.
    options(pager = function(files, header, title, delete.file) {
      for (f in files) {
        lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
        cat(gsub("_\b", "", lines, fixed = TRUE), sep = "\n")
        if (isTRUE(delete.file)) unlink(f)
      }
    })

    # The learner's environment. Its parent switches off quit(), which would end the
    # run without a result.
    sandbox <- new.env(parent = globalenv())
    sandbox$quit <- sandbox$q <- function(...) {
      stop("quit() is switched off in Sample Space.", call. = FALSE)
    }
    learner <- new.env(parent = sandbox)
    .ss$learner <- learner

    if (!is.null(job$data_dir)) {
      data_files <- list.files(job$data_dir, full.names = TRUE)
      data_files <- data_files[!dir.exists(data_files) &
                               !grepl("\\.(R|md|qmd|json)$", data_files, ignore.case = TRUE)]
      file.copy(data_files, out_dir)
    }
    setwd(out_dir)

    if (!is.null(job$setup) && nzchar(job$setup)) {
      eval(parse(text = job$setup, keep.source = FALSE), learner)
    }
    if (!is.null(job$seed)) set.seed(job$seed)

    if (!is.null(job$document) && nzchar(job$document)) {
      knit_document(basename(job$document), learner)
    } else {
      run_script(learner)
    }

    if (!is.null(job$checks) && nzchar(job$checks)) run_checks(job$checks, learner)
  }

  run_script <- function(learner) {
    exprs <- tryCatch(parse(text = .ss$code, keep.source = TRUE), error = function(e) e)
    if (inherits(exprs, "error")) {
      .ss$status <- "parse_error"
      msg <- sub("^<text>:", "line ", conditionMessage(exprs))
      add("error", paste("R couldn't read your code:", msg))
    } else {
      grDevices::png(file.path(out_dir, "plot-%03d.png"), width = 7, height = 5,
                     units = "in", res = 144, bg = "white")
      srcrefs <- attr(exprs, "srcref")
      started <- proc.time()[["elapsed"]]
      setTimeLimit(elapsed = time_limit, transient = FALSE)
      for (i in seq_along(exprs)) {
        add("input", paste(as.character(srcrefs[[i]]), collapse = "\n"))
        if (!eval_one(exprs[[i]], learner)) break
      }
      setTimeLimit()
      .ss$duration <- proc.time()[["elapsed"]] - started
      grDevices::graphics.off()
      files <- list.files(out_dir, pattern = "^plot-\\d+\\.png$")
      files <- sort(files[file.size(file.path(out_dir, files)) > 0])
      .ss$plots <- files
    }
  }

  # --- Documents (Quarto / R Markdown) ----------------------------------------
  # The document is knitted in the learner's environment: chunks run in order, inline `r`
  # values are filled in, and figures are saved as PNG files. Rendering to HTML with Quarto
  # is a separate step the app runs on request.
  split_front_matter <- function(lines) {
    if (length(lines) && trimws(lines[1]) == "---") {
      end <- which(trimws(lines[-1]) %in% c("---", "..."))
      if (length(end)) {
        end <- end[1] + 1L
        yaml <- tryCatch(yaml::yaml.load(paste(lines[2:(end - 1L)], collapse = "\n")),
                         error = function(e) list(.error = conditionMessage(e)))
        return(list(yaml = if (is.list(yaml)) yaml else list(), body = lines[-seq_len(end)]))
      }
    }
    list(yaml = list(), body = lines)
  }

  knit_document <- function(name, learner) {
    .ss$is_document <- TRUE
    input <- file.path(out_dir, name)
    output <- file.path(out_dir, sub("\\.[^.]*$", ".knit.md", name))
    writeLines(enc2utf8(.ss$code), input, useBytes = TRUE)
    head <- split_front_matter(strsplit(.ss$code, "\n", fixed = TRUE)[[1]])
    if (!is.null(head$yaml$.error)) {
      add("warning", paste("The YAML header at the top couldn't be read:", head$yaml$.error))
    }
    .ss$yaml <- head$yaml[names(head$yaml) != ".error"]
    knitr::opts_knit$set(progress = FALSE, verbose = FALSE)
    knitr::opts_chunk$set(error = FALSE, fig.path = "figure-", dev = "png", dpi = 144,
                          fig.width = 7, fig.height = 5, comment = "##")
    quitting <- NULL
    started <- proc.time()[["elapsed"]]
    setTimeLimit(elapsed = time_limit, transient = FALSE)
    ok <- tryCatch(
      withCallingHandlers(
        { knitr::knit(input, output, envir = learner, quiet = TRUE, encoding = "UTF-8"); TRUE },
        message = function(m) {
          text <- trimws(conditionMessage(m))
          if (grepl("^Quitting from", text)) quitting <<- sub("^Quitting from\\s*", "", text)
          else if (nzchar(text)) add("message", text)
          invokeRestart("muffleMessage")
        }
      ),
      error = function(e) {
        setTimeLimit()
        if (is_timeout(e)) {
          .ss$status <- "timeout"
          add("error", sprintf("Knitting ran for more than %s seconds, so it was stopped.", format(time_limit)))
        } else {
          .ss$status <- "error"
          where <- if (is.null(quitting)) "" else {
            lines <- sub("^.*:(\\d+)-(\\d+).*$", "\\1-\\2", quitting)
            parts <- strsplit(lines, "-", fixed = TRUE)[[1]]
            if (length(parts) == 2 && parts[1] == parts[2]) sprintf(": line %s", parts[1])
            else if (length(parts) == 2) sprintf(": lines %s–%s", parts[1], parts[2]) else ""
          }
          call <- call_text(e)
          if (!is.null(call) && grepl("parse_only|eval\\(", call)) call <- NULL
          add("error", sprintf("%s\nKnitting %s stopped here%s.", conditionMessage(e), name, where), call)
        }
        FALSE
      }
    )
    setTimeLimit()
    .ss$duration <- proc.time()[["elapsed"]] - started
    grDevices::graphics.off()
    if (!ok || !file.exists(output)) return(invisible(FALSE))

    body <- split_front_matter(readLines(output, warn = FALSE, encoding = "UTF-8"))$body
    # Figures become {{plot:N}} lines, in the order they appear.
    image <- "^\\s*!\\[[^]]*\\]\\(([^)]+)\\)\\s*$"
    plots <- character()
    for (i in grep(image, body)) {
      file <- sub(image, "\\1", body[i])
      if (file.exists(file.path(out_dir, file)) && file.size(file.path(out_dir, file)) > 0) {
        plots <- c(plots, file)
        body[i] <- sprintf("{{plot:%d}}", length(plots))
      }
    }
    while (length(body) && !nzchar(trimws(body[1]))) body <- body[-1]
    .ss$plots <- plots
    .ss$document <- paste(body, collapse = "\n")
    n_chunks <- length(grep("^\\s*```+\\s*\\{r", strsplit(.ss$code, "\n", fixed = TRUE)[[1]]))
    add("message", sprintf("Knitted %s: %d R chunk%s, %d figure%s. See the Report tab.", name,
                           n_chunks, if (n_chunks == 1) "" else "s", length(plots), if (length(plots) == 1) "" else "s"))
    invisible(TRUE)
  }

  run_checks <- function(check_code, learner) {
    helpers <- new.env(parent = learner)
    helpers$.ss <- .ss
    sys.source(file.path(runner_dir, "checks.R"), envir = helpers, keep.source = FALSE)
    exprs <- tryCatch(parse(text = check_code, keep.source = FALSE), error = function(e) e)
    if (inherits(exprs, "error")) {
      .ss$checks[[length(.ss$checks) + 1L]] <- list(
        passed = FALSE, label = "Level checks", internal = TRUE,
        message = paste("The level's check.R has a syntax error:", conditionMessage(exprs)))
      return(invisible())
    }
    setTimeLimit(elapsed = check_time_limit, transient = FALSE)
    for (expr in exprs) {
      tryCatch(
        suppressWarnings(eval(expr, helpers)),
        error = function(e) {
          .ss$checks[[length(.ss$checks) + 1L]] <- list(
            passed = FALSE, label = "A check couldn't run", internal = TRUE,
            message = conditionMessage(e), step = .ss$step)
        }
      )
    }
    setTimeLimit()
  }

  tryCatch(
    run(),
    error = function(e) {
      setTimeLimit()
      while (sink.number() > 0) sink()
      .ss$status <- "runner_error"
      add("error", paste("Sample Space couldn't run this:", conditionMessage(e)))
    }
  )
  write_result()
})
