# Dissertation Dry Run

**The finale.** Everything from the survey in one document: the Crew Log as a short, complete, reproducible results report. It is a Boss level written in Quarto: **Run** knits it into the Report tab, **Check** shows which of the eight steps pass, and **Render** builds the finished HTML report with Quarto.

## The brief

**Cases.** The log has a row per *mission*; the report needs one row per *astronaut*. Use each person's first mission (`mission_number == 1`): their age at first flight is `year_of_mission − year_of_birth` (approximate), and `total_number_of_missions` is their career.

**RQ1.** Did women and men differ in age at their first flight? (Welch's *t*, Cohen's *d*.)

**RQ2.** Is age at first flight related to how many missions an astronaut went on to fly? The number of missions is a small, skewed count, so use **Spearman's** *r*ₛ (`method = "spearman", exact = FALSE`, because there are many ties).

## The eight steps

1. **Setup:** a real title and your name in the YAML; a hidden setup chunk (`#| include: false`) with the packages, the formatting helpers and `crew`. Adding `knitr::opts_chunk$set(echo = FALSE)` there hides the code of every chunk after it, as a report should.
2. **Cases:** `people`, one row per astronaut.
3. **Participants:** how many astronauts, and how many were women, written by inline R.
4. **Table:** *n*, *M* and *SD* of age by sex, with `knitr::kable()` and the caption *Age at First Flight by Sex*.
5. **Figure:** age at first flight by sex.
6. **RQ1:** the test, then the APA sentence: *t*(df) = …, *p* …, *d* = … .
7. **RQ2:** the test, then the APA sentence: *r*~s~ = …, *p* … . (Type `*r*~s~` for an italic *r* with a subscript s.)
8. **Reproducible:** no statistic typed by hand. The check looks for any "= number" in the words you typed.

> **The log is nearly a population.** As in Inference Station: a test here asks whether a pattern is bigger than the chance variation of the process that produced the log, not whether it exists "in the population" of astronauts. Say so in a sentence; your committee will ask the same of any census-like data.

## Then: your own data

When this report is done, open the **Workbench** in the sidebar. Add your own `.sav` or `.csv` file, start from its results-chapter template, and do the same dry run on your dissertation data. Nothing there is checked or scored, and the files stay on this Mac.
