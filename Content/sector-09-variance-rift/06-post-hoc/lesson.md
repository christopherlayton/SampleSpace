# Post Hoc Probes

The one-way ANOVA said the three programmes' means aren't all equal: *F*(2, 57) = 4.33, *p* = .018. It didn't say *which* differ. With three groups there are three pairs, and testing them one by one at .05 brings back the inflation you met in the p-Hacking Garden. **Post hoc** tests compare every pair while keeping the familywise error rate at .05.

## Tukey HSD

Tukey's *Honestly Significant Difference* is built for all pairwise comparisons of group means after an ANOVA, with equal or similar group sizes and variances:

```r
tukey <- TukeyHSD(fit)
tukey$programme
```

Each row is one pair, `B-A` meaning B's mean minus A's: `diff`, a 95% **familywise** confidence interval (`lwr`, `upr`) and `p adj`. An interval that excludes 0 goes with `p adj` < .05.

## Pairwise t-tests with a correction

```r
pairwise.t.test(pd$efficacy_t2, pd$programme, p.adjust.method = "bonferroni")
```

prints a small triangle of adjusted p-values. By default it uses the pooled SD from all groups, as the ANOVA does. Holm (`"holm"`, the default) is never less powerful than Bonferroni.

| SPSS *Post Hoc…* box | R |
|---|---|
| Tukey | `TukeyHSD(fit)` |
| Bonferroni | `pairwise.t.test(..., p.adjust.method = "bonferroni")` |
| Games-Howell (unequal variances) | `rstatix::games_howell_test(data, y ~ group)` |

## Omnibus and pairs can disagree

A significant F guarantees that *some* contrast among the means is significant, but not necessarily any simple pair, and a pair can look big without surviving the correction. Report what the post hoc tests show, with their intervals, not what you hoped they'd show.

> **APA note:** name the post hoc method, and give each difference with its interval, e.g. "Tukey HSD comparisons showed that group B scored higher than group A, *M*diff = 0.85, 95% CI [0.10, 1.60], *p* = .021; no other pair differed."

## Mission

`pd` is loaded with `programme` in the order Workshop, Coaching, Online, and the one-way ANOVA is in `fit`.

1. Store Tukey's HSD in `tukey` and print the programme table.
2. Store Bonferroni-corrected pairwise t-tests in `pairs_bonf` and Holm-corrected ones in `pairs_holm`.
3. Store the names of the pairs Tukey finds different at .05 in `differ` (row names of the table, e.g. `"Coaching-Workshop"`).

Which pairs survive? Does the Coaching–Workshop gap of 0.74 points?
