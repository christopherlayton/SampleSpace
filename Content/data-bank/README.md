# Data Bank

Real datasets used by Sample Space levels. They are snapshots: a level's checks are written
against the copy here, so don't replace a file with a newer download without re-running
`scripts/validate_content.sh` (and expect some checks to need new numbers).

A level can only read files in its own folder, so each level that uses one of these has its
own copy. Keep those copies identical to the file here.

## astronauts.csv

Every person who had flown in space as of 15 January 2020, one row **per mission**
(1,277 rows, 564 astronauts, 24 variables): sex, year of birth, nationality, military or
civilian, selection programme, mission year and title, mission hours and spacewalk (EVA) hours.

- **Source:** Stavnichuk, M., & Corlett, T. (2020). *Astronaut database* (Version 1) [Data set].
  Mendeley Data. https://doi.org/10.17632/86tsnnbv2w.1 — collected from NASA, Roscosmos and
  other public sources, and analysed in an article by Corlett, Stavnichuk & Komarova (2020).
- **This copy:** the cleaned CSV prepared by Georgios Karamanis for TidyTuesday (2020-07-14),
  https://github.com/rfordatascience/tidytuesday/tree/master/data/2020/2020-07-14,
  downloaded 2026-11-24.
- **Licence:** CC BY 4.0. Use and adapt freely with credit to the authors.
- **Used by:** `sector-02-data-frame-docks/09-crew-manifest`.
- **Note:** the data name real people. Levels use it for group-level questions
  (missions, hours, programmes), not for singling out individuals.
