%% run_all_v842.m
% Full v8.4.2 run: clean, train, evaluate, compare, and plot.

clear; clc; close all;
rootDir = fileparts(mfilename('fullpath'));
[~, lastFolder] = fileparts(rootDir);
if strcmpi(lastFolder, 'code')
    rootDir = fileparts(rootDir);
end
codeDir = fullfile(rootDir, 'code');
resultsDir = fullfile(rootDir, 'results');
figDir = fullfile(rootDir, 'figures');
addpath(codeDir);
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
if ~exist(figDir, 'dir'), mkdir(figDir); end

clean_old_results_for_v842;
par = vpp_default_parameters_v842();

fprintf('\n=== v8.4.2 training started ===\n');
[sacAgent, trainInfo, env] = train_safe_sac_v842(par);
save(fullfile(resultsDir, 'trained_safe_sac_agent_v842.mat'), 'sacAgent', 'trainInfo', 'par', '-v7.3');

fprintf('\n=== v8.4.2 publication tests started ===\n');
run_v842_publication_tests(sacAgent, par);

fprintf('\n=== v8.4.2 plotting started ===\n');
plot_v842_all_results(par);

fprintf('\nDone. Results: %s\nFigures: %s\n', resultsDir, figDir);
