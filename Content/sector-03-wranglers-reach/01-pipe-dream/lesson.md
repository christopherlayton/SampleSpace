# Pipe Dream

Welcome to Wrangler's Reach. Real data need cleaning and reshaping before any analysis, and the tool most R users reach for is **dplyr**, part of the tidyverse. Each dplyr function is a *verb* that does one job to a data frame and returns a new data frame.

## Two verbs

| Verb | Keeps | Example |
|---|---|---|
| `filter()` | **rows** that meet a condition | `filter(astronauts, sex == "female")` |
| `select()` | **columns** you name | `select(astronauts, name, hours_mission)` |

Inside dplyr verbs you write column names bare, without `astronauts$`.

Several conditions in one `filter()`, separated by commas, must **all** be true. For "either", use `|`; for "one of these values", use `%in%`:

```r
filter(astronauts, nationality %in% c("Japan", "China"))
```

## The pipe

`|>` passes the result on its left into the function on its right, as the first argument. Read it as **"and then"**:

```r
astronauts |>
  filter(year_of_mission >= 2010) |>
  select(name, hours_mission)
```

"Take `astronauts`, *and then* keep missions from 2010 on, *and then* keep two columns." Without the pipe you'd nest calls inside each other and read them inside-out. You'll also see `%>%` in older code; it does the same job.

> **Coming from SPSS?** `filter()` is *Data → Select Cases → If condition is satisfied*, and `select()` is like deleting the columns you don't need in a copy of the file. The difference is that nothing changes in `astronauts` itself: you store the result under a new name.

## Mission

1. Load readr and dplyr, and import `astronauts.csv` into `astronauts`.
2. Store the missions flown **from 2010 on**, with only the columns `name`, `nationality`, `year_of_mission` and `hours_mission` (in that order), in `recent`.
3. Store how many missions that is in `n_recent`.
4. Store the missions flown by women that lasted **more than 4,000 hours** in `long_women`.
