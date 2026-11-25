# SPSS Signal, Python Side

The same SPSS file you opened with `haven::read_sav()` in the Data Frame Docks: 30 students, two teaching methods, an exam score and an anxiety rating where 9 = "No answer" was declared missing in SPSS.

Python reads .sav files with **pyreadstat**. It returns *two* things, the data and the metadata, so you unpack them into two names at once:

```python
import pyreadstat
teach, meta = pyreadstat.read_sav("teaching_study.sav")
meta.column_names_to_labels       # variable labels
meta.variable_value_labels        # value labels, per variable
```

## Codes or labels

By default the columns hold the **codes** (1, 2…), and the labels live in `meta`. `apply_value_formats=True` swaps the codes for their labels, the job `haven::as_factor()` did:

| R (haven) | Python (pyreadstat) |
|---|---|
| `teach <- read_sav(file)` | `teach, meta = pyreadstat.read_sav(file)` |
| `as_factor(teach)` | `pyreadstat.read_sav(file, apply_value_formats=True)` |
| declared missing → `NA` | declared missing → `NaN` |
| `mean(x, na.rm = TRUE)` | `x.mean()` (skips `NaN` already) |

pandas has `pd.read_spss()` too; it uses pyreadstat underneath and applies the labels.

{{twin}}

## Mission

1. Import pyreadstat and read `teaching_study.sav` into `teach, meta`.
2. Store the value labels of `method` (a dict) in `method_labels`.
3. Read the file again with the labels applied, into `teach_lab, meta_lab`.
4. Store how many students had "Active learning" in `n_active`.
5. Store how many `anxiety` answers are missing (from `teach`) in `n_no_answer`, and the mean anxiety of those who answered in `mean_anxiety`.
