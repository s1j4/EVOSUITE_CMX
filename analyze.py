
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon, mannwhitneyu, shapiro, kruskal, rankdata



#Evaluate statistics
df1 = pd.read_csv('C:/Users/admin/IdeaProjects/results/statistics.csv')


def varga_delaney(m, n):
    m1 = len(m)
    n1 = len(n)
    r = rankdata(np.concatenate((m, n)))
    r1 = sum(r[:m1])

    # Compute the measure
    A = (2 * r1 - m1 * (m1 + 1)) / (2 * n1 * m1)
    return A

default = df1[df1['configuration_id']=='DEFAULT']
cmx = df1[df1['configuration_id']=='CMX']
coverage = df1[df1['configuration_id']=='COVERAGE']


print("--------------------------------------------------")
print("Compare CMX to DEFAULT:")
for column in ['Coverage', 'BranchCoverage', 'CBranchCoverage']:
    print ("%s: %.2f (%f)" % (column, varga_delaney(cmx[column], default[column]), mannwhitneyu(cmx[column], default[column]).pvalue))


print("--------------------------------------------------")
print("Compare CMX to COVERAGE:")
for column in ['Coverage', 'BranchCoverage', 'CBranchCoverage']:
    print ("%s: %.2f (%f)" % (column, varga_delaney(cmx[column], coverage[column]), mannwhitneyu(cmx[column], coverage[column]).pvalue))

#def get_higher_cmx_coverage():
#    # Get the intersection of TARGET_CLASS values for both dataframes
#    common_classes = set(cmx['TARGET_CLASS']).intersection(set(default['TARGET_CLASS']))
#    # Filter the dataframes to only include the common classes
#    cmx_common = cmx[cmx['TARGET_CLASS'].isin(common_classes)]
#    default_common = default[default['TARGET_CLASS'].isin(common_classes)]
#    # Merge the two dataframes on TARGET_CLASS and compare coverage values
#    merged = cmx_common[['TARGET_CLASS', 'Coverage']].merge(default_common[['TARGET_CLASS', 'Coverage']],
#                                                            on='TARGET_CLASS', suffixes=('_CMX', '_DEFAULT'))
#    merged_branch = cmx_common[['TARGET_CLASS', 'BranchCoverage']].merge(default_common[['TARGET_CLASS', 'BranchCoverage']],
#                                                                          on='TARGET_CLASS', suffixes=('_CMX', '_DEFAULT'))
#    merged_cbranch = cmx_common[['TARGET_CLASS', 'CBranchCoverage']].merge(default_common[['TARGET_CLASS', 'CBranchCoverage']],
#                                                                        on='TARGET_CLASS', suffixes=('_CMX', '_DEFAULT'))
#    high_coverage_df = merged[merged['Coverage_CMX'] > merged['Coverage_DEFAULT']]
#    high_branch_coverage_df = merged_branch[merged_branch['BranchCoverage_CMX'] > merged_branch['BranchCoverage_DEFAULT']]
#    high_cbranch_coverage_df = merged_cbranch[merged_cbranch['CBranchCoverage_CMX'] > merged_cbranch['CBranchCoverage_DEFAULT']]
#    # Save to CSV
#    high_coverage_df.to_csv('C:/Users/admin/IdeaProjects/results/high_coverage.csv', index=False)
#    high_branch_coverage_df.to_csv('C:/Users/admin/IdeaProjects/results/high_branch_coverage.csv', index=False)
#    high_cbranch_coverage_df.to_csv('C:/Users/admin/IdeaProjects/results/high_cbranch_coverage.csv', index=False)
#
#get_higher_cmx_coverage()

print("Compare DEFAULT, CMX, COVERAGE to each other:")
for column in ['Coverage', 'BranchCoverage', 'CBranchCoverage']:
    kruskal_h, kruskal_p = kruskal(default[column], cmx[column], coverage[column])
    mw_p = mannwhitneyu(cmx[column], coverage[column]).pvalue
    print("%s: Kruskal-Wallis H=%.2f, p=%.4f; Mann-Whitney U p=%.4f" % (column, kruskal_h, kruskal_p, mw_p))
#Boxplots
#bp = df1.boxplot(column='Coverage', by='configuration_id')
#bp = df1.boxplot(column='BranchCoverage', by='configuration_id')
#bp = df1.boxplot(column='CBranchCoverage', by='configuration_id')
#plt.show()