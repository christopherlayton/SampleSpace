# Crew Manifest

The ship's data bank holds a real log: **everyone who had flown in space by January 2020**, from Yuri Gagarin onwards. Your job is to check it in, and that starts with one question you should ask of every dataset:

**What is one row?**

## Cases aren't always people

You might expect one row per astronaut. Look closer: John Glenn appears twice, once for his 1962 Mercury flight and once for his 1998 Shuttle flight. In this file **each row is a mission flown by one person**. People who flew several times have several rows.

That changes every count:

| Question | Count rows with… |
|---|---|
| How many missions were flown (person-missions)? | `nrow(astronauts)` |
| How many different people? | `length(unique(astronauts$number))` |
| How many women, as *people*? | one row per person first, then `table()` |

`unique()` keeps one copy of each value; `length()` counts them. Each astronaut has a fixed ID in `number`; IDs are safer than names, which can be spelled two ways.

To get **one row per person**, keep each astronaut's first mission: the rows where `mission_number == 1`.

> **A stats note:** rows from the same person aren't independent: an astronaut who flew five times contributes five similar rows. Most tests you'll meet (*t*-tests, ANOVA, chi-square) assume independent observations, so you'd analyse one row per person, or use a method designed for repeated measurements.

> **APA note:** say what your unit of analysis is and give both counts when they differ, e.g. "1,277 missions flown by 564 astronauts."

> **Coming from SPSS?** This is the *Identify Duplicate Cases* problem. In R you build the one-row-per-person dataset yourself, so you can see exactly which rows were kept.

*Data: Stavnichuk & Corlett (2020), Astronaut database, Mendeley Data (CC BY 4.0), cleaned for TidyTuesday by Georgios Karamanis.*

## Mission

1. Load readr and import `astronauts.csv` into `astronauts`.
2. Store the number of rows in `n_missions`.
3. Store the number of different astronauts in `n_astronauts`, using `unique()` on the ID column `number`.
4. Make `first_flights`: only the rows where `mission_number` is 1.
5. Store a table of `sex` **per person** (from `first_flights`) in `sex_counts`.
