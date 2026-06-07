function [sacAgent, trainInfo, env] = train_safe_sac_v842(par)
%TRAIN_SAFE_SAC_V842 Train Safe-SAC agent with v8.4.2 tariff-aware coach/shield.

rng(par.rngSeed, 'twister');
rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
saveDir = fullfile(resultsDir, 'savedAgents_SAC_v842');
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

shieldOpts = struct('enableSOC', true, 'enableRamp', true, 'enablePeakShield', true, ...
    'enableServiceShield', true, 'enableTerminalShield', true, 'enableEconCoach', true);
env = VPPDataCenterEnv(par, par.train.curriculumMode, shieldOpts);
sacAgent = create_safe_sac_agent_v842(env, par);

trainOpts = rlTrainingOptions;
trainOpts.MaxEpisodes = par.train.maxEpisodes;
trainOpts.MaxStepsPerEpisode = par.train.maxStepsPerEpisode;
trainOpts.ScoreAveragingWindowLength = par.train.scoreAveragingWindowLength;
trainOpts.StopTrainingCriteria = 'AverageReward';
trainOpts.StopTrainingValue = par.train.stopAverageReward;
trainOpts.SaveAgentCriteria = 'AverageReward';
trainOpts.SaveAgentValue = par.train.saveAgentValue;
trainOpts.SaveAgentDirectory = saveDir;
trainOpts.Verbose = true;
trainOpts.Plots = 'training-progress';

fprintf('Training Safe-SAC %s for up to %d episodes using %s curriculum.\n', par.version, par.train.maxEpisodes, par.train.curriculumMode);
trainInfo = train(sacAgent, env, trainOpts);

% Robust checkpoint selection: select saved agent with lowest deterministic objective if available.
bestAgent = sacAgent;
bestObj = inf;
agentFiles = dir(fullfile(saveDir, '*.mat'));
for i = 1:numel(agentFiles)
    f = fullfile(agentFiles(i).folder, agentFiles(i).name);
    S = load(f);
    names = fieldnames(S);
    cand = [];
    for j = 1:numel(names)
        if contains(lower(names{j}), 'agent')
            cand = S.(names{j});
            break;
        end
    end
    if isempty(cand), continue; end
    try
        [summary, ~] = evaluate_agent_vpp(cand, VPPDataCenterEnv(par, 'base'), par);
        if summary.ObjectiveValue < bestObj
            bestObj = summary.ObjectiveValue;
            bestAgent = cand;
        end
    catch ME
        warning('Checkpoint %s could not be evaluated: %s', agentFiles(i).name, ME.message);
    end
end

sacAgent = bestAgent;
fprintf('Selected v8.4.2 agent. Best deterministic objective = %.3f\n', bestObj);
end
