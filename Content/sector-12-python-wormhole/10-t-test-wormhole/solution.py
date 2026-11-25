# 1. One row per astronaut
people = log.groupby("number").agg(
    military_civilian=("military_civilian", "first"),
    mean_hours=("hours_mission", "mean"))

# 2. Describe each group
group_stats = people.groupby("military_civilian")["mean_hours"].agg(["count", "mean", "std", "median"])
group_stats

# 3. The two groups
civ = people.loc[people["military_civilian"] == "civilian", "mean_hours"]
mil = people.loc[people["military_civilian"] == "military", "mean_hours"]

# 4. Levene (SPSS-style), Welch's t-test and Cohen's d
levene = stats.levene(civ, mil, center="mean")
welch = stats.ttest_ind(civ, mil, equal_var=False)
sp = np.sqrt(((len(civ) - 1) * civ.var() + (len(mil) - 1) * mil.var()) / (len(civ) + len(mil) - 2))
d = (civ.mean() - mil.mean()) / sp
levene
welch
d

# 5. Decision at alpha = .05
decision = "reject" if welch.pvalue < 0.05 else "fail to reject"
decision
