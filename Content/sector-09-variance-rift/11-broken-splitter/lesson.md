# Broken Splitter

A colleague's ANOVA script for the programme study. It stops with an error, and even the parts that run give wrong answers. There are **four** bugs: two stop the script and two run silently.

## Silent ANOVA bugs

- **Numeric group codes.** Data exported from SPSS often stores groups as 1, 2, 3. `aov()` treats a number as a number, fits a single slope, and reports **1** df between groups where there should be k − 1. Nothing warns you: check the df.
- **The wrong denominator.** η² is SS between ÷ SS **total**. Dividing by SS within gives a different, larger number (and can exceed 1).

## Mission

Fix the script so that:

1. `fit` is a one-way ANOVA of `efficacy_t2` by programme with 2 between-groups df.
2. `tukey` holds Tukey's HSD for the three programmes.
3. `levene` holds Levene's test, centred on the mean.
4. `eta_sq` is η² for programme.

Keep `group_code` in the data; just don't analyse it as a number.
