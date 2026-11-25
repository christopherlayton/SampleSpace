# First Light

Welcome to Plot Nebula. Some patterns only show up in a picture, and the picture tool most R users reach for is **ggplot2**.

Every ggplot is built from the same three parts:

```r
ggplot(data, aes(x = column)) +   # 1. data, 2. aesthetics: which column goes where
  geom_histogram(bins = 30)       # 3. a geom: what to draw
```

- `ggplot()` names the **data**.
- `aes()` maps **columns** to visual properties: x position, y position, colour, fill…
- A `geom_*()` layer says what shape to draw. Layers are added with **`+`**, not `|>`.

## Histograms

A histogram cuts the x-axis into bins and draws a bar for how many values fall in each. Choose the bins with `bins = 30` (how many) or `binwidth = 2` (how wide). Too few bins hide the shape; too many make noise. Try a few.

## Drawing it

Storing a plot (`p <- ggplot(...)`) doesn't draw it. Type `p` on its own line, or `print(p)`, to draw it. Each drawn plot appears in the **Plots** tab.

> **Coming from SPSS?** *Graphs → Chart Builder → Histogram* gives one chart at a time through a dialog. A ggplot is a line of code you can tweak and rerun, and the same grammar makes every kind of chart.

## Mission

1. Load readr, dplyr and ggplot2 and import `astronauts.csv` into `astronauts`.
2. Store a histogram of `hours_mission` with 40 bins in `p_hours`, and draw it.
3. Make `first_flights`: each astronaut's first mission, with a new column `age` (year of mission minus year of birth).
4. Store a histogram of `age` with a bin width of 2 years in `p_age`, and draw it.

Compare the two shapes. Which one would you describe with a mean and SD?
