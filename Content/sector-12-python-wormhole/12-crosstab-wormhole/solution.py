# 1. First missions, with an ordered era
first = log[log["mission_number"] == 1]
era = pd.Categorical(np.where(first["year_of_mission"] >= 2000, "2000 on", "before 2000"),
                     categories=["before 2000", "2000 on"])
first = first.assign(era=era)

# 2. Counts and row percentages
crew_table = pd.crosstab(first["era"], first["sex"])
row_pct = pd.crosstab(first["era"], first["sex"], normalize="index") * 100
crew_table
row_pct.round(1)

# 3. Chi-square without the correction; are the expected counts big enough?
chi = stats.chi2_contingency(crew_table, correction=False)
expected_ok = (chi.expected_freq >= 5).all()
chi

# 4. Cramer's V
n = crew_table.values.sum()
v = np.sqrt(chi.statistic / (n * (min(crew_table.shape) - 1)))
v
