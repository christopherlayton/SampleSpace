# Broken Report

A draft report from another cadet. It doesn't knit, and once it does, it still isn't right. Run it, read what R and the Report tab say, and fix it.

## What to look for

- **The YAML header.** YAML reads `key: value`. A second colon in the value (`Report: Draft`) makes it look like another key, and the header can't be read. Quote values that contain a colon.
- **Order inside a chunk.** Code runs top to bottom, and so do chunks. A function from a package works only after `library()`.
- **Inline code.** `` `r nrow(crew)` `` is R. `` `nrow(crew)` `` is just text in a code font.
- **Typed numbers.** A number typed into a sentence is a number that goes stale. Every result in a report should come from R.

When the console says *Knitting report.qmd stopped here: line …*, that line number is in the document, so you can jump straight to it.

## Mission

Fix every bug: the document knits, the title is read, the counts come from inline R (1,277 with its comma), and the median mission length is computed, not typed.
