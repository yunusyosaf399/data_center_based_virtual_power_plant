function run_v842_publication_tests(sacAgent, par)
%RUN_V842_PUBLICATION_TESTS Runs v8.4.2 deterministic, ablation, baseline, robustness, stress tests.

if nargin < 2 || isempty(par)
    par = vpp_default_parameters_v842();
end
rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

fprintf('\n--- Deterministic Safe-SAC evaluation ---\n');
[summary, traj] = evaluate_agent_vpp(sacAgent, 'base', par);
save(fullfile(resultsDir, 'v842_deterministic_eval.mat'), 'summary', 'traj', 'par');
writetable(struct2table(orderfields(summary)), fullfile(resultsDir, 'v842_deterministic_summary.csv'));
disp(struct2table(orderfields(summary)));

fprintf('\n--- Controller comparison ---\n');
Tbase = run_v842_controller_comparison(sacAgent, par, 'base');
writetable(Tbase, fullfile(resultsDir, 'v842_controller_comparison_base.csv'));

fprintf('\n--- Shield ablation ---\n');
Tabl = run_v842_ablation_after_training(sacAgent, par);
writetable(Tabl, fullfile(resultsDir, 'v842_ablation_table.csv'));

fprintf('\n--- Stochastic robustness ---\n');
Tsto = run_v842_stochastic_robustness(sacAgent, par);
writetable(Tsto, fullfile(resultsDir, 'v842_stochastic_robustness.csv'));

fprintf('\n--- Combined-stress controller comparison ---\n');
Tstress = run_v842_combined_stress_comparison(sacAgent, par);
writetable(Tstress, fullfile(resultsDir, 'v842_combined_stress_controller_comparison.csv'));

save(fullfile(resultsDir, 'v842_publication_tests_all.mat'), 'summary', 'traj', 'Tbase', 'Tabl', 'Tsto', 'Tstress', 'par');
fprintf('v8.4.2 publication tests saved in %s\n', resultsDir);
end
