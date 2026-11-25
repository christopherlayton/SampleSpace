# 1. Import
import numpy as np
import pandas as pd
from scipy import stats
import seaborn as sns
import matplotlib.pyplot as plt

log = pd.read_csv("astronauts.csv")
first = log[log["mission_number"] == 1]
first = first.assign(age=first["year_of_mission"] - first["year_of_birth"])

# 2. Describe
by_sex = first.groupby("sex")["age"].agg(["count", "mean", "std"])
by_sex

# 3. Plot
sns.boxplot(data=first, x="sex", y="age")
plt.ylabel("Age at first flight")
plt.show()

# 4. Check
women = first.loc[first["sex"] == "female", "age"]
men = first.loc[first["sex"] == "male", "age"]
levene = stats.levene(women, men, center="mean")
levene

# 5. Test
welch = stats.ttest_ind(women, men, equal_var=False)
sp = np.sqrt(((len(women) - 1) * women.var() + (len(men) - 1) * men.var()) / (len(women) + len(men) - 2))
d = (women.mean() - men.mean()) / sp

# 6. Write it up
decision = "reject" if welch.pvalue < 0.05 else "fail to reject"
p_text = "p < .001" if welch.pvalue < .001 else f"p = {welch.pvalue:.3f}".replace("0.", ".", 1)
sentence = (f"Women (M = {women.mean():.2f}, SD = {women.std():.2f}) and men "
            f"(M = {men.mean():.2f}, SD = {men.std():.2f}) differed in age at first flight, "
            f"t({welch.df:.2f}) = {welch.statistic:.2f}, {p_text}, d = {d:.2f}.")
print(sentence)
