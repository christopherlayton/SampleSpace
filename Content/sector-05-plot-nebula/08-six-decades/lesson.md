# Six Decades

Sector review: one figure good enough for a dissertation chapter.

## Labels

`labs()` sets the axis titles, legend title and (if you want one) the title:

```r
labs(x = "Decade", y = "Median mission length (hours)", colour = "Sex")
```

Write axis titles in words, with units, not variable names. Nobody outside your project knows what `hours_mission` means.

## Themes

The default grey background is fine for exploring and wrong for most journals. `theme_classic()` gives white background, axis lines and no gridlines, close to APA figure style. Add `base_size = 12` to scale all the text: `theme_classic(base_size = 12)`.

> **APA figures:** number the figure, give it a title in the text (*Figure 1*, then the title in italics on the next line), label the axes with units, and put notes (what error bars show, how many cases) under the figure. Titles usually go in the document, not inside the image, so leave `title` out of `labs()`.

## Saving

```r
ggsave("six_decades.png", p_final, width = 6, height = 4)
```

Width and height are in inches. Save as PNG at the default 300 dpi for Word, or as PDF for LaTeX/Quarto.

## Mission

1. Load readr, dplyr and ggplot2, import `astronauts.csv`, and store it with a `decade` column in `missions`.
2. Store each decade's median mission length in `decade_medians` (`decade`, `median_hours`).
3. Store a figure in `p_final`: the medians as **points joined by a line**, with the x-axis titled `Decade` and the y-axis `Median mission length (hours)`, using `theme_classic()`. Draw it.
4. Save it as `six_decades.png`, 6 × 4 inches.

The ship can now read the log by decade. What happened in the 2010s?
