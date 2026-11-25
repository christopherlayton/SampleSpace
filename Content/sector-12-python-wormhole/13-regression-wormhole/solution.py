# 1. One row per astronaut: missions and EVA hours
people = log.groupby("number").agg(missions=("id", "size"), eva_hours=("eva_hrs_mission", "sum"))

# 2. Pearson and Spearman
pearson = stats.pearsonr(people["missions"], people["eva_hours"])
spearman = stats.spearmanr(people["missions"], people["eva_hours"])
pearson
spearman

# 3. The regression
model = smf.ols("eva_hours ~ missions", data=people).fit()
print(model.summary())

# 4. Slope and R squared
b = model.params["missions"]
r2 = model.rsquared

# 5. Prediction for 3 missions
eva_for_3 = model.predict(pd.DataFrame({"missions": [3]})).iloc[0]
eva_for_3
