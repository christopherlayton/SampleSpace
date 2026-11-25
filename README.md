# Sample Space

**A macOS game for learning R and the statistics behind a research project.**

You pilot a survey ship across a star map. Every planet is an R skill or a statistics
concept, and every challenge runs **real R** on your Mac and checks your answer. The ship's data
bank holds a real dataset (1,277 space missions flown by 564 astronauts), and each sector you chart
recovers a page of its Crew Log. It was built for someone moving from SPSS to R, so SPSS menus,
syntax and output tables appear alongside the R that reproduces them.

- **13 sectors, 133 levels:** from the R console to a full reproducible Quarto report, plus an optional sector that redoes the analyses in Python.
- **10 interactive Labs:** you *see* a concept before you code it.
- **Review Nebula:** 144 hand-written spaced-repetition cards, plus every quiz question you've answered.
- **Game systems:** XP and ranks, 1–3 stars per level, a daily streak, badges and a recovered story log.

## The curriculum

| # | Sector | R skills | Statistics | Levels |
|---|---|---|---|---|
| 0 | Launch Pad | Console, arithmetic, objects, functions, help | — | 6 |
| 1 | Vector Belt | `c()`, indexing, types, `NA`, factors | Levels of measurement | 11 |
| 2 | Data Frame Docks | Data frames, tibbles, `read_csv`, `haven::read_sav` | Variables vs. cases | 12 |
| 3 | Wrangler's Reach | dplyr verbs, pipes, recoding, missing data | Reverse-scoring, composite scales | 10 |
| 4 | Descriptive Drift | `mean`, `sd`, `psych::describe`, tables | Central tendency, spread, skew, *z*-scores | 8 |
| 5 | Plot Nebula | ggplot2 | Reading distributions visually | 8 |
| 6 | Probability Expanse | `rnorm`, `pnorm`, `sample`, `replicate` | Sampling distributions, CLT, standard error | 9 |
| 7 | Inference Station | Simulation | *p*-values, CIs, Type I/II error, effect size, power | 9 |
| 8 | Means Cluster | `t.test`, `leveneTest`, `cohens_d` | One-sample, independent and paired *t*-tests | 10 |
| 9 | Variance Rift | `aov`, `TukeyHSD`, afex | One-way, factorial and repeated-measures ANOVA | 12 |
| 10 | Relationship Ring | `cor.test`, `chisq.test`, `lm` | Correlation, chi-square, regression | 12 |
| 11 | Dissertation Dock | Quarto, APA tables, project structure | A full reproducible analysis report | 12 |
| 12 | Python Wormhole *(optional)* | pandas, scipy.stats, statsmodels, seaborn | The same analyses in Python, side by side with R | 14 |

Write-ups follow APA style: the checks read your results sentence and point out a wrong *df*, a
leading zero on *p*, or "*p* = .000".

## Level types

| Type | What you do |
|---|---|
| **Briefing** | Read a short lesson, then answer check questions |
| **Code** | Write R in the editor; real R runs it and the checks give specific feedback |
| **Predict** | Guess what the code prints, then see what R really printed |
| **Debug** | Fix code that's broken in the ways beginners' code usually is |
| **SPSS Translate** | Reproduce an SPSS menu path and Output Viewer table in R |
| **Lab** | Reach goals on an interactive simulation, then do the same thing in R |
| **Boss** | A whole analysis in steps: import, clean, check assumptions, test, plot, write it up |

**Labs:** Distribution Sculptor · Sampling Machine · CI Rain · *p*-value Courtroom · Power Reactor ·
Correlation Drag · Least-Squares Fit · ANOVA Splitter · Chi-square Grid · *p*-Hacking Garden.
They're scored inside levels, and you can also play with them freely in the **Lab Bay**.

The **Workbench** is an unscored Quarto document for your own data files. Copies of the files stay
on your Mac.

## Requirements

- **macOS 15 or later** on Apple silicon.
- **R 4.x**, found at `/usr/local/bin/Rscript`, in Homebrew or in R.framework; you can also set
  any path in Settings. It needs these packages:
  ```r
  install.packages(c("tidyverse", "jsonlite", "psych", "car", "effectsize", "rstatix", "afex",
                     "haven", "palmerpenguins", "broom", "knitr", "rmarkdown", "quarto"), repos = "https://cloud.r-project.org")
  ```
- **Quarto** *(optional)*, only to render reports to HTML. Knitting inside the app works without it.
- **Python 3** with `pandas scipy statsmodels matplotlib seaborn pyreadstat` *(optional)*, only
  for the Python Wormhole.

The welcome tour's **systems check** reports what it found and what's missing. You can run it
again from Settings (⌘,).

## Building and installing

Building needs Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
The Xcode project is generated from `project.yml`.

```bash
scripts/run.sh        # build a Debug copy and launch it
scripts/package.sh    # build a Release copy as build/SampleSpace-<version>.pkg (installs into /Applications)
scripts/test.sh       # unit tests; these run real R (and Python, when it's installed)
```

> The scripts set `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`. If you use a
> release Xcode, change that line in each script.

The app and package are signed ad hoc, not with a developer ID. On another Mac, allow the app once
under **System Settings → Privacy & Security → Open Anyway**.

**Launch options:** `-UnlockAll YES` opens every sector and level. `-ProgressFile /path/to/save.json`
plays against a different save; normally progress is saved in
`~/Library/Application Support/SampleSpace/`.

## How it works

- **Engine:** each run is a fresh `Rscript` process (`R/runner.R`). It evaluates your code one
  expression at a time, like the console, with a time limit. It captures output, warnings,
  errors and plots, then runs the level's checks (`R/checks.R`). Python levels use the same
  protocol through `Python/runner.py` and `Python/checks.py`.
- **Content is data:** each level is a folder of plain files under `Content/`:
  `level.json`, `lesson.md`, `starter.R`, `solution.R` and `check.R`. Python levels use `.py`
  files instead, and Quarto levels use `.qmd`. Adding levels doesn't need Swift changes.
- **Validation:** `scripts/validate_content.sh` checks that every solution passes its checks,
  that no starter does, and that every Predict answer matches what R or Python really prints.

More detail: `PLAN.md` (design and build log), `STORY.md` (the storyline, and the code that
reproduces every number it uses), `CLAUDE.md` (conventions).

## Data

The Crew Log is the **astronaut database** by Stavnichuk & Corlett (2020), *Mendeley Data*,
<https://doi.org/10.17632/86tsnnbv2w.1>, licensed **CC BY 4.0**. This copy was cleaned by the
TidyTuesday project (2020-07-14). Levels use it for group-level questions, not to single out
individuals. The other datasets (survey, teaching and training studies) are simulated by
`scripts/make_sample_data.R`. See `Content/data-bank/README.md` for details.
