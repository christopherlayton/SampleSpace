# APA Table

APA tables have a number and a title, italic statistic headers (*n*, *M*, *SD*), the same decimals in every cell of a column, and no vertical lines. In a Quarto document, `knitr::kable()` turns a data frame into exactly that.

```r
knitr::kable(age_table,
             digits = 2,
             col.names = c("Decade", "*n*", "*M*", "*SD*"),
             caption = "Age at First Flight by Decade")
```

- `digits = 2` rounds every number column for display, and pads to two decimals.
- `col.names` renames the headers; `*M*` is Markdown for an italic *M*.
- `caption` becomes the table title. With a chunk label starting `tbl-` (`#| label: tbl-age`), Quarto numbers it "Table 1" when you **Render**.
- `#| echo: false` keeps the code out of the report: readers want the table, not the R.

> **From the Crew Log:** the Variance Rift asked whether age at first flight changed across the decades. This is the descriptive table that would sit above that ANOVA in a results chapter.

## Mission

In the `tbl-age` chunk:

1. Make `age_table`: one row per astronaut (first missions), `decade` written like `1960s`, `age` at first flight, and per decade `n`, `M` and `SD` of age.
2. Show it with `knitr::kable()`: two decimals, the headers Decade, *n*, *M*, *SD*, and the caption *Age at First Flight by Decade*.
3. Hide the chunk's code.

Run it and look at the Report tab, then **Render** to see the HTML table.
