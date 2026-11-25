# Reproducible Reports

Last sector. The ship's computer can now read the whole Crew Log. One task is left: **turn it into a report that rebuilds itself.**

## Point-and-click vs. code

In SPSS, a results chapter is usually made by hand: run an analysis, copy a number out of the Output Viewer, paste it into Word, repeat a few hundred times. Change one data point and every number has to be found and fixed again.

A **reproducible report** is built by code. The raw data go in, and the tables, figures and sentences come out. Fix the data, render again, and every number updates. It is also a record of exactly what you did, which is what a committee (or you, in two years) needs.

## A Quarto document

Quarto (`.qmd`) is plain text with three kinds of part:

````qmd
---
title: "Chapter 4: Results"
author: "A. Cadet"
format: html
---

```{r}
#| label: setup
#| include: false
library(readr)
crew <- read_csv("astronauts.csv")
```

The log holds `r nrow(crew)` missions.
````

1. **YAML header** between the `---` lines: title, author, output format (`html`, `docx`, `pdf`).
2. **Chunks**: R code between ```` ```{r} ```` and ```` ``` ````. Options go on `#|` lines at the top.
3. **Inline code**: `` `r ...` `` inside a sentence. R replaces it with the value.

## Chunk options you'll use

| Option | Code shown | Output shown | Code runs |
|---|---|---|---|
| (none) | yes | yes | yes |
| `#| echo: false` | no | yes | yes |
| `#| include: false` | no | no | yes |
| `#| eval: false` | yes | no | no |

> **Coming from SPSS?** A Quarto document is like an SPSS syntax file and its Output Viewer and your Word document rolled into one, where the output is regenerated every time.

In this sector you'll knit documents in the app (**Run**), check them, and render the real report with Quarto (**Render**).
