# Storing Cargo

Typing numbers over and over gets old fast. Instead, store a value in a named **object** with the assignment arrow `<-` (read it as "gets"):

```r
n_pilots <- 12
n_pilots * 2
#> [1] 24
```

Saving a value prints nothing. To see what an object holds, type its name on a line by itself.

## Naming objects

- Names start with a letter and can contain letters, numbers, `_` and `.`. No spaces.
- Names are **case-sensitive**: `Score` and `score` are different objects.
- Pick names that say what the value is. Most R code uses `snake_case`, like `mean_age`.
- Assigning to a name that already exists replaces its old value, with no warning.

`=` also works for assignment, but most R code uses `<-`, so this ship does too.

> **Coming from SPSS?** *Compute Variable* adds a column to your one open dataset. An R object can hold anything: one number, a whole dataset, a fitted model, a plot. You can have many datasets open at once, each in its own object.

## Mission

A survey wave returned **40** completed questionnaires, and the mean satisfaction score was **3.8** on a 1–5 scale.

1. Store 40 in an object called `n_responses`.
2. Store 3.8 in an object called `mean_satisfaction`.
3. Create `total_points` by multiplying those two **objects** together. Use their names, not the numbers.
4. Print `total_points`.
