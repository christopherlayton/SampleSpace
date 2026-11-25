# Sample Space — notes for Claude

A personal macOS SwiftUI game for learning R and statistics (doctoral student moving from SPSS to R for a dissertation). The full design and the step checklist are in `PLAN.md`.

## How to work in this repo
- When asked to "do the next step", read `PLAN.md`, do the first unchecked step only, then tick its box and add a dated line to the Decisions log.
- Finish each session with the app building. If a step can't be finished, write what's left under that step in `PLAN.md`.
- Commit at the end of each step.

## Build
- `scripts/build.sh` — regenerates the Xcode project from `project.yml` and builds into `build/`.
- `scripts/run.sh` — builds, then launches the app.
- `scripts/test.sh` — runs the unit tests (they run real R through `REngine`).
- Launch flags: `-ProgressFile /path.json` plays against another save; `-UnlockAll YES` opens every sector and level (to try content behind unwritten sectors).

Xcode-beta is the only Xcode and is not the selected toolchain, so the scripts set
`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`. Use the same prefix for any direct `xcodebuild` call.
`SampleSpace.xcodeproj` is generated and git-ignored: edit `project.yml`, never the `.pbxproj`.

## Conventions
- App Sandbox is off (the app runs `/usr/local/bin/Rscript`).
- The R harness is `R/runner.R` + `R/checks.R` (documented at the top of each); Swift side is `SampleSpace/Engine/`.
- Levels are folders under `Content/sector-NN-slug/` (level.json, lesson.md, starter.R, solution.R, check.R, optional setup.R and data files); each sector has a sector.json. Check helpers are listed at the top of `R/checks.R`. Run `scripts/validate_content.sh` after adding or changing levels: solutions must pass and starters must not. Lab levels add a `lab` object (instrument kind, settings, goals on its readings; see `Models/Lab.swift`). Briefing/Predict levels add a `quiz` list and need no R files (`Models/Quiz.swift`); SPSS Translate levels add an `spss` object shown at a `{{spss}}` line in lesson.md (`Models/SPSS.swift`); Debug levels' starter is the broken code.
- Story: `STORY.md`. Each sector.json needs `briefing` and `log`; story numbers must come from `Content/data-bank/` with the R that reproduces them in STORY.md, and analysis-sector entries pose questions, not results.
- Stats explanations should be correct and APA-aware; the learner's coursework covers t-tests, ANOVA, chi-square, correlation and regression.
