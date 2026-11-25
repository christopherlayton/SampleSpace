# Backwards Formula

A teammate's analysis of the wellbeing study. It stops with an error, and once it runs, one of its tests is the wrong test, and nothing warns you.

## Formula rules

`outcome ~ group`: the thing you measured on the **left**, the grouping variable on the **right**. Reverse them and R tries to split the data by every distinct anxiety score, then complains that the "grouping factor" doesn't have exactly two levels.

A formula names columns, so the function also needs to know **where** they live: `data = survey`. Without it, R looks for objects called `anxiety_post` and `group` in your workspace and doesn't find them.

## The silent bug

The worst bugs give an answer. `t.test(pre, post)` without `paired = TRUE` runs Welch's two-group test as if the pre- and post-test came from different people. It gives a *t*, a *df* and a *p*, all wrong for this design: the SE ignores that each person's two scores are linked. Always ask: same people, or different people?

> **From the Crew Log:** the same trap waits in the log, where each astronaut can appear on several rows. A test that treats rows as independent people counts some astronauts several times. That's why this sector's review works one row per person.

## Mission

Fix the script so that it runs and stores:

- `groups_test`: Welch's *t*-test of `anxiety_post` by `group`,
- `levene`: Levene's test (SPSS's version) of `anxiety_post` by group,
- `change_test`: the paired *t*-test of pre- against post-test anxiety,
- `d`: Cohen's *d* for the group difference in `anxiety_post`.

There are **four** bugs. Keep the object names as they are.
