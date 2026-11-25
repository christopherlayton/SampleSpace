# Ship's Manual

No pilot memorises every control. What matters is knowing how to look things up. In R, every function has a **help page**:

```r
?seq          # the full help page
help(seq)     # the same thing
args(seq)     # just the arguments and their defaults
```

A help page always has the same parts: *Description*, *Usage* (how to call it), *Arguments* (what each input means), *Value* (what comes back) and *Examples*. When a function surprises you, start with *Arguments*, then try the *Examples*.

## Making sequences

`seq()` makes a regular sequence of numbers. Its arguments are `from`, `to` and `by`:

```r
seq(from = 10, to = 30, by = 5)
#> [1] 10 15 20 25 30
```

For whole numbers that go up by 1 there's a shortcut, the colon operator:

```r
1:5
#> [1] 1 2 3 4 5
```

Notice that a sequence is several numbers stored together. That's a **vector**, and the next sector is all about them.

> **Coming from SPSS?** SPSS hides the arguments behind dialog boxes and the *Paste* button. In R the arguments *are* the dialog: each checkbox or field becomes a named argument such as `by = 25` or `na.rm = TRUE`.

## Mission

You're setting up the anchors for a rating slider and a questionnaire.

1. Open the help for `seq()` with `?seq` (or `args(seq)`).
2. Store the slider anchors **0, 25, 50, 75, 100** in `checkpoints`, using `seq()` with the `from`, `to` and `by` arguments named.
3. A 7-point Likert scale runs from 1 to 7. Store those points in `likert_points` using the `:` shortcut.
