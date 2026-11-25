# 1. Import pandas and read the Crew Log
import pandas as pd
log = pd.read_csv("astronauts.csv")

# 2. Rows and columns
n_rows = log.shape[0]
n_columns = log.shape[1]

# 3. How many different people?
n_people = log["number"].nunique()

# 4. The most missions anyone flew
most_missions = log["number"].value_counts().max()

# 5. The first rows
log.head()
