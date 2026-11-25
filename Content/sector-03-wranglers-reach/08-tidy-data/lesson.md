# Tidy Data

The same data can be laid out more than one way, and different tools expect different layouts.

## Wide and long

A pre/post study, **wide** (one row per student):

| id | group | anxiety_pre | anxiety_post |
|---|---|---|---|
| S01 | Mindfulness | 40 | 30 |
| S02 | Mindfulness | 30 | 28 |

The same data, **long** (one row per student per occasion):

| id | group | time | anxiety |
|---|---|---|---|
| S01 | Mindfulness | pre | 40 |
| S01 | Mindfulness | post | 30 |
| S02 | Mindfulness | pre | 30 |
| S02 | Mindfulness | post | 28 |

## Tidy data

A dataset is **tidy** when each variable is a column, each observation is a row and each value is a cell. In the long table, `time` is a variable with its own column. In the wide table, it's hidden in the column *names*.

Neither layout is wrong. Paired *t*-tests and SPSS's repeated-measures dialogs want wide data; ggplot, `group_by()` and mixed models want long data. **tidyr** converts between them:

- `pivot_longer()`: wide → long (columns become rows)
- `pivot_wider()`: long → wide (rows become columns)

> **Coming from SPSS?** SPSS calls this *Data → Restructure* (variables to cases and back). In R it's one line each way.

## Mission

This is a **briefing**: five questions on the right. The next level puts the pivots to work.
