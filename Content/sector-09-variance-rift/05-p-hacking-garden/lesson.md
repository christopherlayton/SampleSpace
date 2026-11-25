# p-Hacking Garden

α = .05 promises one thing: if H₀ is true, **one** test will be falsely significant 5% of the time. It promises nothing about a study that runs many tests and reports the ones that worked.

## The garden of forking paths

Every study in this garden compares two groups drawn from the **same** population. There is never a real effect, so every red flower is a false alarm. Two common habits make flowers bloom:

- **Many outcomes.** Measure ten outcomes, report whichever is significant. With independent outcomes, P(at least one false alarm) = 1 − (1 − α)ᵏ, about 40% for k = 10.
- **Peeking.** Test after every few participants and stop as soon as p < .05. Each look is another chance.

Others work the same way: trying several outlier rules, covariates or subgroups and keeping the one that "works". The fix is to decide the analysis **before** seeing the data (preregistration), and to correct for the tests you do run.

## Correcting for many tests

| Method | Each test is judged at | In R |
|---|---|---|
| Bonferroni | α ÷ m | `p.adjust(p, "bonferroni")` |
| Holm | α ÷ m, α ÷ (m − 1), … in order | `p.adjust(p, "holm")` |
| Tukey HSD | built for all pairs of group means | `TukeyHSD(fit)` (next level) |

All three keep the **familywise** error rate, the chance of any false alarm across the set, at α.

## The lab

Set the outcomes per study, the number of looks, n and α, then run studies in batches. Changing a setting clears the garden. Reach the four goals to open stage 2.

## Mission

Simulate the many-outcomes garden in R (the seed is set for you). `one_study()` runs ten independent t-tests on pure noise and returns their p-values.

1. Run 1,000 studies: `p_values <- replicate(1000, one_study())`, a 10 × 1000 matrix.
2. Store, for each study, whether any outcome had p < .05 in `any_hit`, and the share of studies with a hit in `rate`.
3. Store the theoretical rate 1 − .95¹⁰ in `theory`.
4. Store the share of studies with a hit when each p is compared with .05 / 10 in `bonf_rate`.
5. A paper reports five p-values, in `reported`. Store their Holm-adjusted values in `holm` and Bonferroni-adjusted values in `bonf`.
