# Mean age at first flight, and the top three nations for first-time flyers
import pandas
log = pd.read_csv("astronauts.csv")

first = log[log["mission_number"] = 1]
first = first.assign(age=first["year_of_mission"] - first["year_of_birth"])

mean_age = first["Age"].mean
top_three = first["nationality"].value_counts()[1:4]
