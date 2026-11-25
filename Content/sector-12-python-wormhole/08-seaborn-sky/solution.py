# 1. Import the plotting libraries
import seaborn as sns
import matplotlib.pyplot as plt

# 2. Histogram of mission length
sns.histplot(data=log, x="hours_mission", bins=40)
plt.xlabel("Hours per mission")
plt.show()

# 3. First missions, with age and decade
first = log[log["mission_number"] == 1]
first = first.assign(age=first["year_of_mission"] - first["year_of_birth"],
                     decade=first["year_of_mission"] // 10 * 10)

# 4. Boxplot of age by decade
sns.boxplot(data=first, x="decade", y="age")
plt.ylabel("Age at first flight")
plt.show()
