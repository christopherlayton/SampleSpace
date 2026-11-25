# Wormhole Turbulence

This script was translated from R by someone in a hurry. It should store the mean age at first flight in `mean_age` and the three nationalities with the most first-time flyers in `top_three`. There are **five** bugs, each an R habit that means something else (or nothing) in Python.

Python reports one problem at a time, and a *syntax* error comes first: Python reads the whole script before running any of it, so a line it can't read stops even the lines above it.

| R habit | Python |
|---|---|
| `library(pandas)`-style names | `import pandas as pd` makes the name `pd` |
| `mean(x)` | `x.mean()`: the `()` *calls* the method |
| `x[1:3]` is the first three | `x[0:3]` is the first three |
