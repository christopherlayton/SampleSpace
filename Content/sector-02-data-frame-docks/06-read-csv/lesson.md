# CSV Cargo

Most data reach R as files. The most portable format is **CSV** (comma-separated values): plain text, one row per line, commas between columns. Excel, Qualtrics, REDCap and SPSS can all export it.

The tidyverse reader is `read_csv()` from the **readr** package:

```r
library(readr)
survey <- read_csv("wellbeing_survey.csv")
```

It prints a short *column specification*, its guess at each column's type. **Read it.** If a column you expected to be numeric shows as `chr`, something in the file isn't a number (remember Signal Decoder). Add `show_col_types = FALSE` to hide the message once you've checked.

Empty cells become `NA` automatically.

## Where does R look for the file?

`read_csv("wellbeing_survey.csv")` looks in the **working directory**. Here, Sample Space puts the level's data files there for you. In your own projects, keep data inside the project folder and use an RStudio/Positron project (or the `here` package) so paths keep working on any computer; avoid `setwd()` with a full path to your Desktop.

> **Coming from SPSS?** This is *File → Import Data → CSV Data*, but written down. Rerun the script next month and you get exactly the same dataset, with no clicking through the import wizard again.

## Mission

`wellbeing_survey.csv` holds a two-group mindfulness study: each student's group, demographics, anxiety before and after (10–50), and satisfaction (1–5).

1. Load readr and import the file into `survey`.
2. Store the number of students in `n_students`.
3. Store the group counts in `group_counts` using `table()`.
4. Store the mean post-test anxiety, ignoring missing values, in `mean_post`.
