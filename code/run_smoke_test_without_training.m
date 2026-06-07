%% run_smoke_test_without_training.m
% Fast syntax/path/env test. Does not train SAC.

clear; clc; close all;
thisDir = fileparts(mfilename('fullpath'));
[~, lastFolder] = fileparts(thisDir);
if strcmpi(lastFolder, 'code')
    rootDir = fileparts(thisDir);
    codeDir = thisDir;
else
    rootDir = thisDir;
    codeDir = fullfile(rootDir, 'code');
end
addpath(codeDir);
if ~exist(fullfile(rootDir, 'results'), 'dir'), mkdir(fullfile(rootDir, 'results')); end
if ~exist(fullfile(rootDir, 'figures'), 'dir'), mkdir(fullfile(rootDir, 'figures')); end

par = vpp_default_parameters_v842();
env = VPPDataCenterEnv(par, 'base');
obs = reset(env);
assert(numel(obs) == 22, 'Observation vector must have 22 states.');

for k = 1:5
    [obs, r, done, logSig] = step(env, 0.0); %#ok<ASGLU>
    if done
        break;
    end
end

fprintf('Environment smoke test passed. Last reward = %.4f\n', r);

[summary, traj] = simulate_controller_v842(par, 'base', 'rule', []);
disp(struct2table(orderfields(summary)));

rootDir = fileparts(codeDir);
save(fullfile(rootDir, 'results', 'smoke_test_v842.mat'), 'summary', 'traj', 'par');
fprintf('Smoke test results saved.\n');
