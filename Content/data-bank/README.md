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
- **Used by:** `sector-02-data-frame-docks/11-crew-manifest`; Wrangler's Reach (Pipe Dream,
  Course Correction, Fleet Summary, Typo Patrol, Crew Roster); Descriptive Drift (Which Average?,
  Spread Scanner, Standard Candles, The Long Tail); Plot Nebula (all code levels except Error
  Bars); Probability Expanse (Sampling Machine lab, Jammed Simulator, Crew Lottery); Inference
  Station (Shuffle Test); Means Cluster (Military or Civilian?); Variance Rift (Ages Across
  Decades); Relationship Ring (Crew Crosstab, Crew Connections); Dissertation Dock (First
  Report, APA Table, Broken Report, Dissertation Dry Run); Python Wormhole (every code level
  except First Contact and SPSS Signal, Python Side) and the Workbench's starting copy.
- **Known quirks** (taught, not fixed): nationality typos "Hungry", "Malysia", "Netherland";
  occupations in mixed capitals; ID (`number`) 385 is shared by two people (Baturin and Duque),
  so counting IDs gives 564 where there are 565 people; six missions have 0 hours.
- **Note:** the data name real people. Levels use it for group-level questions
  (missions, hours, programmes), not for singling out individuals.
