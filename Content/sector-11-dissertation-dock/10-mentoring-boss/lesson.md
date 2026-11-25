# Does Mentoring Help Students Belong?

**Boss level.** A whole study, start to finish, the way your dissertation analysis will run: one script, seven steps. Press **Check** whenever you like. The step bar shows which steps pass; each step opens when the one before it passes, and the level is cleared when all seven do.

## The study

84 first-year students were randomly assigned to **peer mentoring** or a **control** group. At the end of the year they answered a five-item *sense of belonging* scale (1 = Strongly disagree … 5 = Strongly agree), saved by SPSS as `belonging_study.sav`:

| Item | Wording |
|---|---|
| b1 | I feel I belong at this university |
| b2 | I often feel like an outsider here *(reverse-worded)* |
| b3 | People here accept me as I am |
| b4 | I feel isolated on campus *(reverse-worded)* |
| b5 | I am part of the university community |

Code 9 means "No answer" and is declared missing in SPSS, so `read_sav()` reads it as `NA`.

**Research question:** do mentored students report a greater sense of belonging than controls?

## The seven steps

1. **Import.** Read the file; make `condition` and `first_gen` factors with `as_factor()`.
2. **Score.** Reverse-score b2 and b4 (6 − x on a 1–5 scale). The scale score is the mean of the five items for students who answered **at least four**; others get `NA` and are left out of `analysed`. Report internal consistency: Cronbach's α (`psych::alpha()`) on the scored items.
3. **Describe** each group: *n*, *M*, *SD*.
4. **Assumptions.** Levene's test as SPSS runs it (`center = mean`) and Shapiro–Wilk in each group.
5. **Test** with Welch's *t* (R's default) and size it with Cohen's *d*, whatever *p* is.
6. **Plot** the two distributions.
7. **Write it up.** Decide at α = .05, then write the sentence: both groups' *M* and *SD*, then *t*, *p* and *d*.

> **A result you don't expect is still a result.** If the test isn't significant, say so plainly: "did not differ significantly", with the statistics. Don't call it "approaching significance", and don't read "no evidence of a difference" as "evidence of no difference". The CI and *d* tell the reader how big a difference the data allow.

`fmt_num()`, `fmt_p()` and `fmt_bounded()` are loaded.
