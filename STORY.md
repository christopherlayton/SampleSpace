# Sample Space — the story

## Premise

You're a cadet aboard the survey ship *Sample Space*. Its data bank carries the **Crew Log**:
the real record of every person who flew in space from 1961 to 2019 (564 astronauts,
1,277 missions; Stavnichuk & Corlett, 2020, CC BY 4.0, see `Content/data-bank/README.md`).

The ship's computer can store the log but can't interpret it. It speaks R. Each sector you
chart teaches a skill, and with it the ship **recovers one entry of the log**: a real finding
from the data, worked out by the skills you just learned. By the Dissertation Dock you'll
have turned the whole log into one reproducible report, the same journey your dissertation
data will take.

## Rules for the story

- **Every number is real** and comes from `Content/data-bank/astronauts.csv`. The code that
  produces each one is below. If the data file changes, rerun it and update the text.
- **Descriptive facts can be told; test results can't.** Early entries report what the log
  shows (counts, medians, trends). Entries for the analysis sectors (7–11) state the
  *question* and what you did. The answer is the learner's to compute, not a spoiler.
- **The log is nearly a population, not a sample.** Inference Station makes that point
  explicitly: a test on the full log asks whether a pattern is bigger than chance variation
  in the process, not whether it "exists in the population".
- **Group-level only.** Named people appear only for public firsts and records (first flight,
  first woman, longest mission, most missions). No lesson asks about an individual's
  personal details.
- Ages are approximate: the log has year of birth and year of mission, not dates.
- **"564 astronauts" counts IDs.** In the source, ID 385 is shared by two people (Yuri Baturin
  and Pedro Duque), so there are really 565 people. The game follows the source's IDs, as the
  published database does, and Crew Roster (Wrangler's Reach) points the problem out as a
  lesson in checking that an ID identifies one person.

## Where the story appears

- **Sector arrival** (`briefing` in `sector.json`): shown in the sector panel on the map.
- **Recovered log entry** (`log` in `sector.json`): shown once the sector is charted, on the
  completion card of the level that charts it, and in the Ship's Log on the Pilot Profile.
- **"From the Crew Log" call-outs** in lessons, where a skill meets the real data.
- **Labs:** the Sampling Machine (Probability Expanse) uses the log's hours per mission as its
  population, so "drawing random crews" is literally sampling missions from the log.

## Log entries by sector

| # | Sector | Arrival hook | Recovered entry |
|---|---|---|---|
| 0 | Launch Pad | The computer stores the log but can't read it; it speaks R. | Vostok 1, 1961: Gagarin, 1.77 hours. 1,277 missions since. |
| 1 | Vector Belt | Each column is a vector with a type. | 564 astronauts, 40 nationality entries, 27 with one person. |
| 2 | Data Frame Docks | What is one row? | Rows are missions: 1,277 rows, 564 people; 202 flew once; two flew seven times. |
| 3 | Wrangler's Reach | The log is messy ("Hungry", "Malysia", "pilot" vs "Pilot"). | One clean row per astronaut; 232 made at least one spacewalk. |
| 4 | Descriptive Drift | Which average? | Median mission 261 h vs mean 1,051 h; longest 10,505 h (Polyakov, ≈ 438 days, from 1994). |
| 5 | Plot Nebula | Patterns need pictures. | Median mission 96 h (1960s) → 3,912 h (2010s, ≈ 163 days). First-time flyers who were women: 1 of 44 (1960s) → 11 of 55 (2010s). |
| 6 | Probability Expanse | Draw random crews from the log. | Small random crews vary a lot; bigger crews settle near the full log. |
| 7 | Inference Station | Is the rise in women more than chance? What does a p-value mean for a near-complete population? | Hypotheses filed. |
| 8 | Means Cluster | Do military and civilian astronauts fly missions of different lengths? | Tested, one row per person, with an effect size. |
| 9 | Variance Rift | Mean age at first flight: ≈ 35 (1960s) → ≈ 42 (2010s). Bigger than the spread within decades? | Compared with ANOVA after checking assumptions. |
| 10 | Relationship Ring | More missions, more spacewalk hours? Military status and nationality? | Correlation, regression and chi-square on the log. |
| 11 | Dissertation Dock | Turn it all into one reproducible report. | Report filed. The survey is complete. |
| 12 | Python Wormhole | The same log in another language. | Analyses reproduced in Python. |

## Reproducing the facts

```r
a <- read.csv("Content/data-bank/astronauts.csv", encoding = "UTF-8")
f <- a[a$mission_number == 1, ]          # one row per astronaut (their first mission)
nrow(a); nrow(f)                          # 1277 missions, 564 astronauts
a[order(a$year_of_mission, a$id), ][1, c("name", "year_of_mission", "hours_mission")]  # Gagarin, 1961, 1.77
tn <- table(f$nationality); length(tn); sum(tn == 1)                # 40 entries, 27 with one person
sum(f$total_number_of_missions == 1)                                 # 202 flew once
unique(a$name[a$total_number_of_missions == 7])                      # Ross, Chang-Diaz
length(unique(a$number[a$total_eva_hrs > 0]))                        # 232 spacewalkers
median(a$hours_mission); mean(a$hours_mission)                       # 261, 1051
a[which.max(a$hours_mission), c("name", "year_of_mission", "hours_mission")]  # Polyakov, 1994, 10505
decade <- floor(a$year_of_mission / 10) * 10
tapply(a$hours_mission, decade, median)                              # 95.9 ... 3912
fd <- floor(f$year_of_mission / 10) * 10
tapply(f$sex == "female", fd, sum); table(fd)                        # 1 of 44 ... 11 of 55
tapply(f$year_of_mission - f$year_of_birth, fd, mean)                # 35.3 ... 41.6
sd(a$hours_mission)                                                  # 1714.8 (Sampling Machine: σ ≈ 1,715)
age <- f$year_of_mission - f$year_of_birth; mean(age); sd(age)      # 40.3, 5.25 (Distribution Sculptor)
c("Hungry", "Malysia") %in% f$nationality                           # TRUE TRUE (typos in the source)
c("pilot", "Pilot") %in% a$occupation                                # TRUE TRUE (inconsistent capitals)
"Netherland" %in% f$nationality                                     # TRUE (a third nationality typo)
r <- tapply(a$eva_hrs_mission, a$number, sum); length(r); sum(r > 0) # 564 IDs, 232 spacewalkers (Crew Roster)
unique(a$name[a$number == 385])                                      # Baturin, Duque: one ID, two people
sum(f$sex == "female"); mean(f$sex == "female")                      # 64, .113 (Crew Lottery)
table(ifelse(f$year_of_mission >= 2000, "2000 on", "before 2000"))  # 172, 392 (Shuffle Test eras)
```
