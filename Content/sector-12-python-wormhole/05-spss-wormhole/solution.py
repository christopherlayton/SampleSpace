# 1. Read the SPSS file: the data and its metadata
import pyreadstat
teach, meta = pyreadstat.read_sav("teaching_study.sav")

# 2. The value labels of method
method_labels = meta.variable_value_labels["method"]
method_labels

# 3. Again, with the labels applied
teach_lab, meta_lab = pyreadstat.read_sav("teaching_study.sav", apply_value_formats=True)

# 4. How many had Active learning?
n_active = (teach_lab["method"] == "Active learning").sum()

# 5. Missing anxiety answers, and the mean of the rest
n_no_answer = teach["anxiety"].isna().sum()
mean_anxiety = teach["anxiety"].mean()
mean_anxiety
