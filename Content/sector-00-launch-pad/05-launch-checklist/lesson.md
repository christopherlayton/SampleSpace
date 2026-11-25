# Launch Checklist

Before leaving the Launch Pad, one last pre-flight check that uses everything so far: objects, arithmetic, order of operations and functions. The calculation is one you'll use constantly in statistics, the **z-score**.

## What a z-score says

A z-score tells you how many standard deviations a score lies above or below the mean:

**z = (score − mean) ÷ SD**

| z | Meaning |
|---|---|
| `0` | exactly at the mean |
| `1.5` | one and a half SDs **above** the mean |
| `-2` | two SDs **below** the mean |

Because z-scores are in SD units, they let you compare scores from tests with different scales. You'll meet them again in the Descriptive Drift and Probability Expanse sectors.

In R, remember the order of operations: `my_score - class_mean / class_sd` would divide **first**. Wrap the subtraction in parentheses.

> **APA note:** z-scores, like most statistics, are usually reported to two decimal places, e.g. *z* = 1.60. Statistical symbols such as *z*, *M* and *SD* are italicised.

## Mission

On a methods quiz the class mean was **60** and the standard deviation was **5**. You scored **68**; a classmate scored **52**.

1. Store the numbers in `my_score`, `class_mean` and `class_sd`.
2. Calculate your z-score from those **objects** and store it in `z`.
3. Calculate the classmate's z-score (52) and store it in `z_classmate`.
4. Print `z` rounded to 2 decimal places with `round()`.
