import numpy as np
import pandas as pd
from scipy import stats
log = pd.read_csv("astronauts.csv")
import statsmodels.api as sm
import statsmodels.formula.api as smf
from statsmodels.stats.multicomp import pairwise_tukeyhsd
from statsmodels.stats.oneway import anova_oneway
