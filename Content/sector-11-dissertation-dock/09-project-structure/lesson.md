# Shipshape Projects

A reproducible report needs a reproducible project around it: someone else (your advisor, a journal, you in three years) should be able to open the folder and get the same numbers.

## Five habits

1. **One folder per project**, opened as an RStudio or Positron project, so the working directory is always the project folder.
2. **Raw data are read-only.** Never edit or save over the file you collected. Cleaning happens in code, and the cleaned data are an *output*.
3. **Relative paths.** `read_sav("data/raw/survey.sav")`, never `C:/Users/...` or `setwd()`.
4. **Seeds for anything random** (simulations, bootstraps, random assignment): `set.seed()`, and say which seed in your methods.
5. **Freeze package versions with renv.**

```r
renv::init()      # once: gives the project its own package library
renv::snapshot()  # after installing or updating packages: writes renv.lock
renv::restore()   # elsewhere: installs exactly the versions in renv.lock
```

renv isn't installed on this Mac yet, so this level only shows the commands. When you set up your dissertation project, run `install.packages("renv")` and then `renv::init()` in it.

## A layout that works

```r
thesis/
  thesis.Rproj        # opens the project
  renv.lock           # package versions
  data/raw/           # as collected, never edited
  data/clean/         # written by code
  R/01-clean.R        # numbered scripts, run in order
  chapter-4.qmd       # the results chapter
  output/figures/     # rebuilt every render
```

> **Coming from SPSS?** SPSS keeps the data, the syntax and the output in three windows that drift apart. Here the code is the single source: the clean data, every table and every sentence come from it.

Then `sessionInfo()` at the end of a report prints the R and package versions it was built with: a one-line insurance policy.
