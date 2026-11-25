# First Report

Your first document. The editor on the right holds a Quarto file, not an R script: **Run** knits it (R runs each chunk and fills in the inline code) and the **Report** tab shows the result.

## Numbers from code, not from the keyboard

````qmd
The log holds `r format(nrow(crew), big.mark = ",")` missions.
````

knits to *The log holds 1,277 missions.* `format(x, big.mark = ",")` adds the thousands separator APA style expects.

If you typed "1,277" instead, the sentence would look the same today, and be wrong the day the data change. The checks here make sure R wrote the numbers.

## A hidden setup chunk

Loading packages and reading data is housekeeping; readers don't need to see it. Put it in a first chunk with `#| include: false`: it still runs, and its objects are there for everything after it.

## Mission

1. Give the document the title `Crew Log Report` in the YAML header.
2. Make the setup chunk hidden (`include: false`), load readr and read `astronauts.csv` into `crew`.
3. Finish the sentence so R fills in the number of missions (with a comma: 1,277) and the number of astronauts (unique `number`s).

Press **Run** to knit and look at the Report tab. When it reads right, try **Render** too: Quarto builds the HTML report and opens it.
