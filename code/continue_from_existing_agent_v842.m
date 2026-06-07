%% continue_from_existing_agent_v842.m
% Optional: continue training from an existing v8.3/v8.4 agent file.
% Edit oldAgentFile before running.

clear; clc; close all;
thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
rootDir = fileparts(thisDir);
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

par = vpp_default_parameters_v842();
oldAgentFile = fullfile(resultsDir, 'trained_safe_sac_agent_v83.mat');

if ~exist(oldAgentFile, 'file')
    error('Agent file not found. Edit oldAgentFile in continue_from_existing_agent_v842.m.');
end
S = load(oldAgentFile);
names = fieldnames(S);
sacAgent = [];
for i = 1:numel(names)
    if contains(lower(names{i}), 'agent')
        sacAgent = S.(names{i});
        break;
    end
end
if isempty(sacAgent)
    error('No agent variable found in %s', oldAgentFile);
end

shieldOpts = struct('enableSOC', true, 'enableRamp', true, 'enablePeakShield', true, ...
    'enableServiceShield', true, 'enableTerminalShield', true);
env = VPPDataCenterEnv(par, 'stochastic', shieldOpts);

trainOpts = rlTrainingOptions;
trainOpts.MaxEpisodes = 500;
trainOpts.MaxStepsPerEpisode = par.N;
trainOpts.ScoreAveragingWindowLength = 60;
trainOpts.StopTrainingCriteria = 'AverageReward';
trainOpts.StopTrainingValue = par.train.stopAverageReward;
trainOpts.Verbose = true;
trainOpts.Plots = 'training-progress';
trainInfo = train(sacAgent, env, trainOpts);

save(fullfile(resultsDir, 'continued_safe_sac_agent_v842.mat'), 'sacAgent', 'trainInfo', 'par', '-v7.3');
run_v842_publication_tests(sacAgent, par);
plot_v842_all_results(par);
