function T = run_v842_combined_stress_comparison(sacAgent, par)
%RUN_V842_COMBINED_STRESS_COMPARISON Baseline comparison under combined stress.

T = run_v842_controller_comparison(sacAgent, par, 'combined-stress');
rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
save(fullfile(resultsDir, 'v842_combined_stress_controller_comparison.mat'), 'T', 'par');
end
