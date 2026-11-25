expect_true(identical(document_yaml()$title, "Crew Log Report"), label = "The YAML header sets the title",
            message = "Between the `---` lines: `title: \"Crew Log Report\"`.")
chunks <- document_chunks()
setup <- if (length(chunks)) chunks[[1]] else NULL
expect_true(!is.null(setup) && any(grepl("^include:\\s*false", setup$options)), label = "The setup chunk is hidden",
            message = "Add `#| include: false` at the top of the setup chunk, so it runs but shows nothing.")
crew <- get_object("crew")
expect_true(is.data.frame(crew) && nrow(crew) == 1277, label = "The setup chunk reads the log into `crew`",
            message = "`crew <- read_csv(\"astronauts.csv\", show_col_types = FALSE)` (after `library(readr)`).")
expect_true(!grepl("read_csv", document_text(), fixed = TRUE), label = "The report doesn't show the setup code",
            message = "The setup code shows in the report. Hide that chunk with `#| include: false`.")
expect_computed("1,277", label = "R writes the number of missions, with a comma",
                message = "Use `` `r format(nrow(crew), big.mark = \",\")` `` so R writes 1,277.")
expect_computed("564", label = "R writes the number of astronauts",
                message = "Count unique IDs inline: `` `r length(unique(crew$number))` ``.")
expect_true(!grepl("\\b1277\\b", prose_text()), label = "No typed mission count is left",
            message = "The sentence still has a typed 1277. Replace it with inline code.")
