import csv
import matplotlib.pyplot as plt
import pandas as pd
import re

#Calculates average + variance for each combination of config & class, for each criterium (e.g., Coverage, Branch_Coverage, etc)
df = pd.read_csv('C:/Users/admin/IdeaProjects/results/statistics.csv') #Replace with your own path
grouped = df.groupby(['configuration_id']).agg({
    'Coverage': ['mean'],
    'BranchCoverage': ['mean'],
    'CBranchCoverage': ['mean'],
    'Total_Branches': ['mean'],
    'Covered_Branches': ['mean'],
    'Covered_Branches_Real': ['mean'],
    'Total_Goals': ['mean'],
    'Covered_Goals;': ['mean']
})
grouped.reset_index(inplace=True)
grouped.to_csv('C:/Users/admin/IdeaProjects/results/average.csv', index=False)  #Replace with your own path
print(grouped)


