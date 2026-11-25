# 1. First missions, with age and decade
first = log[log["mission_number"] == 1]
first = first.assign(age=first["year_of_mission"] - first["year_of_birth"],
                     decade=first["year_of_mission"] // 10 * 10)

# 2. The model and its ANOVA table
model = smf.ols("age ~ C(decade)", data=first).fit()
table = sm.stats.anova_lm(model, typ=2)
table

# 3. Effect size
eta2 = table["sum_sq"].iloc[0] / table["sum_sq"].sum()
eta2

# 4. Tukey's HSD
tukey = pairwise_tukeyhsd(first["age"], first["decade"])
print(tukey.summary())

# 5. Levene's test and Welch's ANOVA
levene = stats.levene(*[g["age"] for _, g in first.groupby("decade")], center="mean")
welch = anova_oneway(first["age"], first["decade"], use_var="unequal")
levene

# 6. Which test fits, and the decision
test_used = "welch" if levene.pvalue < 0.05 else "classic"
p_used = welch.pvalue if test_used == "welch" else table["PR(>F)"].iloc[0]
decision = "reject" if p_used < 0.05 else "fail to reject"
test_used, decision
