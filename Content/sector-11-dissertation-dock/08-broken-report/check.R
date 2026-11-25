expect_no_error(label = "The document knits", message = "It stopped with an error: the Console tab says where.")
expect_true(identical(document_yaml()$title, "Crew Log Report: Draft"), label = "The YAML header is read, title and all",
            message = "Quote the title, because it contains a colon: `title: \"Crew Log Report: Draft\"`.")
expect_computed("1,277", label = "The mission count comes from inline R",
                message = "Inline code starts with `r`: `` `r format(nrow(crew), big.mark = \",\")` ``.")
expect_computed("261", label = "The median is computed, not typed",
                message = "Replace the typed 261 with `` `r round(median(crew$hours_mission))` ``.")
