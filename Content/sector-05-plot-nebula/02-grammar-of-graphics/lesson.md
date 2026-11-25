# Grammar of Graphics

ggplot2 implements Leland Wilkinson's *grammar of graphics*: instead of a menu of chart types, a few parts that combine into any chart.

| Part | Question it answers | Example |
|---|---|---|
| **Data** | What data frame? | `ggplot(astronauts, ...)` |
| **Aesthetics** | Which column goes where? | `aes(x = decade, y = hours, fill = sex)` |
| **Geoms** | What shape? | `geom_point()`, `geom_boxplot()`, `geom_bar()` |
| **Scales** | How do values become positions and colours? | `scale_y_log10()` |
| **Labels and themes** | What's written, and how it looks | `labs(...)`, `theme_classic()` |

Layers stack with `+`, in order: later layers are drawn on top.

## Mapping vs setting

```r
geom_point(aes(colour = sex))   # map: colour depends on each row's sex
geom_point(colour = "navy")     # set: every point is navy
```

Mapping makes a legend. Setting doesn't.

## Common aesthetics

`x`, `y`, `colour` (points, lines, outlines), `fill` (inside bars and boxes), `size`, `shape`, `alpha` (transparency, 0–1).

## Mission

A **briefing**: five questions on the right.
