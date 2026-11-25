# Function Thrusters

A **function** takes some input, does something with it, and returns a result. You call it with its name followed by parentheses. The inputs, called **arguments**, go inside the parentheses:

```r
sqrt(81)
#> [1] 9
```

## Arguments, by position or by name

Many functions take more than one argument. `round()` takes a number `x` and how many `digits` to keep:

```r
round(3.14159, 2)            # by position
round(3.14159, digits = 2)   # by name: clearer, and the order no longer matters
#> [1] 3.14
```

Naming arguments makes code easier to read, especially when you return to it months later. Arguments you leave out use their **defaults**. `round()` keeps `digits = 0` unless you say otherwise.

## Getting help

Every function has a help page. Type `?round` (or `help(round)`) to read it, or `args(round)` to see just its arguments and defaults. Help pages always follow the same order: *Description*, *Usage*, *Arguments*, *Value*, *Examples*. The examples at the bottom are often the quickest way in.

> **APA note:** APA style commonly reports means and standard deviations to two decimal places, so `round(x, digits = 2)` will come up a lot. R rounds exact halves to the nearest even number (`round(2.5)` is `2`), following the IEC 60559 standard. That is why R can disagree with what you'd round by hand.

## Mission

The starter code gives you `reaction_times`, six reaction times in milliseconds made with `c()` ("combine"). You'll learn `c()` properly in the next sector.

1. Store the mean reaction time in `avg_rt`.
2. Store `avg_rt` rounded to **2** decimal places in `avg_rt_rounded`. Use the `digits` argument by name.
3. Store the fastest (smallest) reaction time in `fastest`. Use a function rather than reading it off yourself.
