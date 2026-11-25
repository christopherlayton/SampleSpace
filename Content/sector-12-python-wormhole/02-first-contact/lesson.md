# First Contact

Python stores things with `=` (there is no `<-`), and a list of values is written in square brackets:

```python
hours = [1.77, 25.0, 5.0, 213.0, 5.0]
```

These are the first five missions in the Crew Log, in hours (Gagarin's 1.77 h comes first).

## Built in, and imported

A few functions come with Python: `len()` counts items, `sum()` adds them up, `round()`, `min()` and `max()` do what you'd expect. There is **no built-in `mean()`**: statistics come from libraries, which you `import` first.

```python
import numpy as np
np.mean(hours)
```

## Positions start at 0

```python
hours[0]     # the first mission: 1.77
hours[-1]    # negative positions count from the end: the last
hours[1:3]   # positions 1 and 2 (the end, 3, is left out): [25.0, 5.0]
```

In R, `hours[1]` is the first value and `hours[2:3]` the second and third. Python's slice `start:end` stops *before* `end`, so `hours[1:3]` has 3 − 1 = 2 items.

{{twin}}

## Mission

1. Make `hours`, the list above.
2. Store how many missions it holds in `n`, their sum in `total`, and `total / n` in `mean_hours`.
3. Store the first mission's hours in `first` and a list of the **last two** in `last_two`.
4. Import numpy as `np` and store `np.mean(hours)` in `np_mean`. It should equal `mean_hours`.
