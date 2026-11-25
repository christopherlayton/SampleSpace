# 1. First missions only, with age
first = log[log["mission_number"] == 1]
first = first.assign(age=first["year_of_mission"] - first["year_of_birth"])

# 2. First-time flyers per nationality
by_nation = first["nationality"].value_counts()
top_nation = by_nation.index[0]

# 3. Count and mean age by sex
ages = first.groupby("sex")["age"].agg(["count", "mean"])
ages

# 4. The three oldest first-time flyers
oldest = first.sort_values("age", ascending=False).head(3)[["name", "age"]]
oldest
