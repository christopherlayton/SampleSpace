# Reading the Console

Before going further, learn to read what R says back. Most of a programmer's day is reading the console, and R's messages are more helpful than they first look.

## The prompt

- `>` means R is ready for a new expression.
- `+` means R thinks your expression **isn't finished** yet: a bracket or quote is still open.

## The `[1]`

```r
seq(100, 220, by = 5)
#>  [1] 100 105 110 115 120 125 130 135 140 145 150 155 160 165
#> [15] 170 175 180 185 190 195 200 205 210 215 220
```

The number in square brackets is the **position** of the first value on that line. It helps you count along long results. It has nothing to do with lines of code.

## Three kinds of feedback

| R says | What it means | What to do |
|---|---|---|
| **Error** | R stopped. Nothing after this point ran. | Read the message, fix the cause, run again. |
| **Warning** | R finished, but something looked wrong. | Check the result. Don't ignore it. |
| **Message** | Information, e.g. which columns a file had. | Read it once; it's not a problem. |

The two errors you'll meet most:

- `object 'x' not found`: you haven't created `x` yet, or you spelled it differently.
- `could not find function "f"`: a typo, the wrong capitals, or the package with `f()` isn't loaded with `library()`.

> **Coming from SPSS?** SPSS puts warnings in a box at the top of the Output Viewer, and it's easy to scroll past them. In R they appear right under the line that caused them. Treat them like the SPSS warnings box you always meant to read.

## Mission

This is a **briefing**: answer the four questions on the right. Pick an answer (or press its number), then lock it in. Every answer right first time earns the third star.
