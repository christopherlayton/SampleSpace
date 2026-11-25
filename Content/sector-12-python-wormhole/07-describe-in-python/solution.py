# 1. The column, its mean and median
hours = log["hours_mission"]
mean_hours = hours.mean()
median_hours = hours.median()

# 2. Two standard deviations
sd_hours = hours.std()
sd_numpy = np.std(hours)

# 3. Shape
skew_hours = hours.skew()
kurt_hours = hours.kurt()

# 4. IQR and the whole description
iqr_hours = hours.quantile(0.75) - hours.quantile(0.25)
hours.describe()
