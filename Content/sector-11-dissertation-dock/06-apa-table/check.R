truth <- utils::read.csv("astronauts.csv")
f <- truth[truth$mission_number == 1, ]
age <- f$year_of_mission - f$year_of_birth
decade <- paste0(floor(f$year_of_mission / 10) * 10, "s")
want_m <- tapply(age, decade, mean)
want_sd <- tapply(age, decade, sd)
tab <- get_object("age_table")
ok_tab <- is.data.frame(tab) && nrow(tab) == 6 && all(c("decade", "n", "M", "SD") %in% names(tab))
expect_true(ok_tab, label = "`age_table` has one row per decade with `n`, `M` and `SD`",
            message = "Six rows (1960s to 2010s): first missions only, then `group_by(decade) |> summarise(n = n(), M = mean(age), SD = sd(age))`.")
if (ok_tab) {
  tab <- as.data.frame(tab)
  expect_true(identical(sort(as.character(tab$decade)), sort(names(want_m))),
              label = "Decades are written like 1960s", message = "`decade = paste0(floor(year_of_mission / 10) * 10, \"s\")`.")
  tab <- tab[order(as.character(tab$decade)), ]
  expect_true(isTRUE(all.equal(as.numeric(tab$M), as.numeric(want_m))) && isTRUE(all.equal(as.numeric(tab$SD), as.numeric(want_sd))),
              label = "`M` and `SD` are age at first flight",
              message = "Age is `year_of_mission - year_of_birth`, on first missions only (`mission_number == 1`).")
}
doc <- document_text()
expect_true(grepl("Age at First Flight by Decade", doc, fixed = TRUE), label = "The table has its caption",
            message = "`caption = \"Age at First Flight by Decade\"` in `knitr::kable()`.")
expect_true(grepl("|*M*", gsub(" ", "", doc), fixed = TRUE) && grepl("|*SD*", gsub(" ", "", doc), fixed = TRUE) &&
              grepl("|*n*", gsub(" ", "", doc), fixed = TRUE),
            label = "Headers are italic *n*, *M*, *SD*", message = "`col.names = c(\"Decade\", \"*n*\", \"*M*\", \"*SD*\")`.")
expect_true(grepl(formatC(want_m[["1960s"]], format = "f", digits = 2), doc, fixed = TRUE) &&
              grepl(formatC(want_sd[["1990s"]], format = "f", digits = 2), doc, fixed = TRUE),
            label = "Numbers are shown to two decimals", message = "`digits = 2` in `knitr::kable()`.")
expect_true(!grepl("kable(", doc, fixed = TRUE) && !grepl("summarise(", doc, fixed = TRUE),
            label = "The report shows the table, not the code", message = "Add `#| echo: false` to the `tbl-age` chunk.")
