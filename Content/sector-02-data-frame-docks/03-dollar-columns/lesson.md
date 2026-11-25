# Column Cargo

The `$` operator pulls one column out of a data frame as an ordinary vector:

```r
penguins$species
penguins$flipper_length_mm
```

Because it's a vector, everything from the Vector Belt works on it: `mean()`, `sum(is.na(...))`, `table()`, filters in `[ ]`.

## Adding a variable

Assign to a column name that doesn't exist yet and R adds it:

```r
penguins$flipper_cm <- penguins$flipper_length_mm / 10
```

The calculation happens for every row at once, like vector arithmetic. Assigning to an existing column replaces it.

Typing in RStudio or Positron, `penguins$` pops up a list of column names. Here you'll need to spell them yourself; `names(penguins)` reminds you.

> **Coming from SPSS?** `penguins$body_mass_kg <- penguins$body_mass_g / 1000` is *Transform → Compute Variable* in one line, and it's written down, so you (and your committee) can see exactly how every variable was made.

## Mission

`penguins` is loaded.

1. Store the number of missing body masses in `n_missing_mass` (calculate it this time).
2. Store the mean body mass in grams, ignoring missing values, in `mean_mass`.
3. Add a column `body_mass_kg` to `penguins`: body mass in **kilograms** (grams ÷ 1000).
