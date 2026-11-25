# The first five missions in the Crew Log, in hours
hours = [1.77, 25.0, 5.0, 213.0, 5.0]

# 2. How many, the total, and the mean
n = len(hours)
total = sum(hours)
mean_hours = total / n

# 3. The first mission, and the last two
first = hours[0]
last_two = hours[-2:]

# 4. The mean again, with numpy
import numpy as np
np_mean = np.mean(hours)
np_mean
