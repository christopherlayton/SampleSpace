# Pandas Docks

**pandas** is Python's data frame library. `pd.read_csv()` reads a CSV into a `DataFrame`, like `read_csv()` from readr:

```python
import pandas as pd
log = pd.read_csv("astronauts.csv")
log.head()       # the first 5 rows, like head()
log.shape        # (rows, columns), like dim()
log.columns      # column names, like names()
log.info()       # types and missing values, a bit like str()
```

## One column

`log["number"]` picks a column (a `Series`), like `log$number`. Its methods answer the usual questions:

| R | pandas |
|---|---|
| `length(unique(log$number))` | `log["number"].nunique()` |
| `table(log$number)` | `log["number"].value_counts()` |
| `max(table(log$number))` | `log["number"].value_counts().max()` |

Notice that nothing here is a test: this is the same discovery you made in the Data Frame Docks. A row of the log is a **mission**, not a person.

{{twin}}

## Mission

1. Import pandas as `pd` and read `astronauts.csv` into `log`.
2. Store the number of rows in `n_rows` and of columns in `n_columns`.
3. Store how many different astronaut `number`s there are in `n_people`.
4. Store the most missions flown by one person in `most_missions`.
5. Show the first rows with `log.head()`.
