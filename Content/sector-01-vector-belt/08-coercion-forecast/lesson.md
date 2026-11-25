# Coercion Forecast

You've met R's types and seen it convert between them. Now test your instincts: **predict** what each piece of code prints *before* R runs it.

A quick reminder of the rules:

- A vector holds **one type**. When types mix, R *coerces* everything to the most flexible type present: **logical → numeric → character**.
- As numbers, `TRUE` is `1` and `FALSE` is `0`, so `sum()` counts `TRUE`s and `mean()` gives their proportion.
- Turning text that isn't a number into a number gives `NA`, with a warning.
- A calculation that includes `NA` gives `NA`, unless you add `na.rm = TRUE`.

> **Why predict?** Guessing first and then checking is one of the fastest ways to learn. A wrong guess tells you exactly which rule you haven't got yet, and you remember the surprise.

## Mission

Five predictions on the right. Pick the output you expect and lock it in. Once you're right, R runs the code for real so you can compare. Every prediction right first time earns the third star.
