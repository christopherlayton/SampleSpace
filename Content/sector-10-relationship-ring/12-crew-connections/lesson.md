# Crew Connections

The two questions from your arrival at the Relationship Ring:

1. **Do astronauts who fly more missions log more spacewalk (EVA) hours?** Two numeric variables: correlation, then regression.
2. **Is military status related to nationality?** Two categorical variables: a χ² test of independence.

## One row per astronaut, again

Both questions are about people, so start from one row per astronaut `number`, as in Crew Roster: their number of missions in the log, their total EVA hours (the sum over their missions), and their military status and nationality from their first row. The log has 40 nationality entries, 27 of them with a single person, so group nationality into **U.S.**, **U.S.S.R/Russia** and **Other** to keep every expected count healthy.

## Things to notice before you trust a number

- Most astronauts never made a spacewalk, so `eva_hours` piles up at 0 with a long right tail. Plot it. Pearson's r assumes a linear pattern and is sensitive to extreme values; Spearman's rho, on ranks, is the check.
- With 564 people, a small correlation can be "significant". Read r (and r²), not just p.
- A regression of EVA hours on missions describes the average increase per extra mission. It doesn't say that flying more *causes* spacewalks: the arrow could run through role, era or agency.

## Mission

`astronauts` is loaded with readr, dplyr, ggplot2 and effectsize.

1. Make `people`: one row per `number`, with `missions`, `eva_hours`, `military_civilian` and `nationality`; then add `nation` (`"U.S."`, `"U.S.S.R/Russia"` or `"Other"`).
2. Store a scatterplot of `eva_hours` against `missions` in `p` (use `geom_jitter()`, since missions are whole numbers).
3. Store the Pearson test in `pearson` and the Spearman test (`exact = FALSE`) in `spearman`.
4. Store the regression of `eva_hours` on `missions` in `model`, and its slope in `b`.
5. Store the nation × military status counts in `crosstab`, its χ² test in `chi` and the unadjusted Cramér's V in `v`.
6. Store your decisions at α = .05 in `decision_r` (from Pearson) and `decision_chi`: `"reject"` or `"fail to reject"`.

Then read your results. How strong is each relationship, and what would you say about it in a report?
