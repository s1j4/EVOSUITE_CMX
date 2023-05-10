import pandas as pd
import numpy as np
from scipy.stats import mannwhitneyu, rankdata

def varga_delaney(m, n):
    m1 = len(m)
    n1 = len(n)
    r = rankdata(np.concatenate((m, n)))
    r1 = sum(r[:m1])

    # Compute the measure
    A = (2 * r1 - m1 * (m1 + 1)) / (2 * n1 * m1)
    return A


df = pd.read_csv('C:/Users/admin/IdeaProjects/results/statistics.csv')

coverage = df[df['configuration_id']=='COVERAGE']
cmx = df[df['configuration_id']=='CMX']

common_classes = set(cmx['TARGET_CLASS']).intersection(set(coverage['TARGET_CLASS']))
# Create an empty list to hold the results
coverage_result_list = []
bcoverage_result_list = []
cbcoverage_result_list = []
# Loop through each target class
for target_class in common_classes:
    # Filter the dataframe to include only the current target class
    target_class_df = df[df['TARGET_CLASS'] == target_class]

    # Get the values for each criterion for the CMX and coverage configurations
    coverage_cmx = target_class_df[target_class_df['configuration_id'] == 'CMX']['Coverage']
    coverage_coverage = target_class_df[target_class_df['configuration_id'] == 'COVERAGE']['Coverage']
    mean_coverage_cmx = coverage_cmx.mean()
    mean_coverage_coverage = coverage_coverage.mean()
    branch_coverage_cmx = target_class_df[target_class_df['configuration_id'] == 'CMX']['BranchCoverage']
    branch_coverage_coverage = target_class_df[target_class_df['configuration_id'] == 'COVERAGE']['BranchCoverage']
    mean_bcoverage_cmx = branch_coverage_cmx.mean()
    mean_bcoverage_coverage = branch_coverage_coverage.mean()
    cbranch_coverage_cmx = target_class_df[target_class_df['configuration_id'] == 'CMX']['CBranchCoverage']
    cbranch_coverage_coverage = target_class_df[target_class_df['configuration_id'] == 'COVERAGE']['CBranchCoverage']
    mean_cbcoverage_cmx = cbranch_coverage_cmx.mean()
    mean_cbcoverage_coverage = cbranch_coverage_coverage.mean()

    #Compare mean values
    higher_coverage = mean_coverage_cmx - mean_coverage_coverage
    higher_branch_coverage = mean_bcoverage_cmx - mean_bcoverage_coverage
    higher_cbranch_coverage = mean_cbcoverage_cmx - mean_cbcoverage_coverage

    # Compute the Cohen's d value for each criterion
    cohens_d_coverage = varga_delaney(coverage_cmx, coverage_coverage)
    cohens_d_branch_coverage = varga_delaney(branch_coverage_cmx, branch_coverage_coverage)
    cohens_d_cbranch_coverage = varga_delaney(cbranch_coverage_cmx, cbranch_coverage_coverage)

    # Compute the Mann-Whitney U p-value for each criterion
    mwu_pvalue_coverage = mannwhitneyu(coverage_cmx, coverage_coverage).pvalue
    mwu_pvalue_branch_coverage = mannwhitneyu(branch_coverage_cmx, branch_coverage_coverage).pvalue
    mwu_pvalue_cbranch_coverage = mannwhitneyu(cbranch_coverage_cmx, cbranch_coverage_coverage).pvalue

    # Create a dictionary with the results for the current target class and combined coverage
    coverage_result = {
        'TARGET_CLASS': target_class,
        'Coverage_CMX': mean_coverage_cmx,
        'Coverage_Coverage': mean_coverage_coverage,
        'CMX_vs_Coverage': higher_coverage,
        'P_Coverage': mwu_pvalue_coverage,
        'Effect_Coverage': cohens_d_coverage
    }

    # Create a dictionary with the results for the current target class and branch coverage
    bcoverage_result = {
        'TARGET_CLASS': target_class,
        'Branch_Coverage_CMX': mean_bcoverage_cmx,
        'Branch_Coverage_Coverage': mean_bcoverage_coverage,
        'Branch_CMX_vs_Coverage': higher_branch_coverage,
        'P_BranchCoverage': mwu_pvalue_branch_coverage,
        'Effect_BranchCoverage': cohens_d_branch_coverage
    }

    # Create a dictionary with the results for the current target class and cbranch coverage
    cbcoverage_result = {
        'TARGET_CLASS': target_class,
        'CBranch_Coverage_CMX': mean_cbcoverage_cmx,
        'CBranch_Coverage_Coverage': mean_cbcoverage_coverage,
        'CBranch_CMX_vs_Coverage': higher_cbranch_coverage,
        'P_CBranchCoverage': mwu_pvalue_cbranch_coverage,
        'Effect_CBranchCoverage': cohens_d_cbranch_coverage
    }
    # Add the results for the current target class to the list of all results
    coverage_result_list.append(coverage_result)
    bcoverage_result_list.append(bcoverage_result)
    cbcoverage_result_list.append(cbcoverage_result)
# Convert the list of results to a dataframe and write it to a CSV file
coverage_result_df = pd.DataFrame(coverage_result_list)
coverage_result_df.to_csv('C:/Users/admin/IdeaProjects/results/vgcoverage_comparison_results2.csv', index=False)
bcoverage_result_df = pd.DataFrame(bcoverage_result_list)
bcoverage_result_df.to_csv('C:/Users/admin/IdeaProjects/results/vgbranch_coverage_comparison_results2.csv', index=False)
cbcoverage_result_df = pd.DataFrame(cbcoverage_result_list)
cbcoverage_result_df.to_csv('C:/Users/admin/IdeaProjects/results/vgcbranch_coverage_comparison_results2.csv', index=False)

#df1 = pd.read_csv('C:/Users/admin/IdeaProjects/results/coverage_comparison_results2.csv')
#df2 = pd.read_csv('C:/Users/admin/IdeaProjects/results/branch_coverage_comparison_results2.csv')
#df3 = pd.read_csv('C:/Users/admin/IdeaProjects/results/cbranch_coverage_comparison_results2.csv')



#bp1 = df1.boxplot(column='CMX_vs_Coverage', by='TARGET_CLASS')
#bp2 = df2.boxplot(column='Branch_CMX_vs_Coverage', by='TARGET_CLASS')
#bp3 = df3.boxplot(column='CBranch_CMX_vs_Coverage', by='TARGET_CLASS')

#df1 = df1.filter(df1['P_Coverage'] <= 0.05)
#fbp1 = df1.boxplot(column='CMX_vs_Coverage', by='TARGET_CLASS')

#plt.show()