import pandas as _pd
_log = _pd.read_csv("astronauts.csv")
_first = _log[_log["mission_number"] == 1]
_first = _first.assign(age=_first["year_of_mission"] - _first["year_of_birth"])
_f = get_object("first")
expect_true(_f is not None and len(_f) == 564, label="`first` has one row per astronaut (564)",
            message="Keep the rows where `mission_number` is 1: `log[log[\"mission_number\"] == 1]` (note the `==`).")
expect_true(_f is not None and "age" in getattr(_f, "columns", []) and abs(_f["age"].mean() - _first["age"].mean()) < 1e-9,
            label="`first` has an `age` column",
            message="`first = first.assign(age=first[\"year_of_mission\"] - first[\"year_of_birth\"])`.")
expect_object("by_nation", _first["nationality"].value_counts(), message="`first[\"nationality\"].value_counts()` counts and sorts.")
expect_object("top_nation", "U.S.", message="`by_nation.index[0]` is the first label (positions start at 0).")
_a = get_object("ages")
expect_true(_a is not None and list(getattr(_a, "columns", [])) == ["count", "mean"]
            and int(_a.loc["female", "count"]) == 64 and int(_a.loc["male", "count"]) == 500
            and abs(_a.loc["female", "mean"] - _first.loc[_first.sex == "female", "age"].mean()) < 1e-9,
            label="`ages` has the count and mean age of women and men",
            message="`first.groupby(\"sex\")[\"age\"].agg([\"count\", \"mean\"])`.")
_o = get_object("oldest")
expect_true(_o is not None and list(getattr(_o, "columns", [])) == ["name", "age"] and len(_o) == 3
            and list(_o["age"]) == sorted(_first["age"], reverse=True)[:3],
            label="`oldest` holds the three oldest, with name and age",
            message="Sort by age, largest first (`ascending=False`), take `.head(3)`, then select `[[\"name\", \"age\"]]`.")
expect_called("assign")
expect_called("groupby")
