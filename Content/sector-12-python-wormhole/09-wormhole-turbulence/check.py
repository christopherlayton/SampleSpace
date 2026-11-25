import pandas as _pd
_log = _pd.read_csv("astronauts.csv")
_first = _log[_log["mission_number"] == 1]
_ages = _first["year_of_mission"] - _first["year_of_birth"]
expect_no_error()
_m = get_object("mean_age")
expect_true(_m is None or not callable(_m), label="`mean_age` is a number, not a method",
            message="`.mean` without brackets is the method itself. Call it: `.mean()`.")
expect_object("mean_age", _ages.mean(), message="The mean of the `age` column (lower-case) of first missions.")
expect_object("top_three", _first["nationality"].value_counts().head(3),
              message="The top three are positions 0, 1 and 2: `[0:3]`, or `.head(3)`.")
