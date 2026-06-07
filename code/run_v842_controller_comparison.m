function T = run_v842_controller_comparison(sacAgent, par, mode)
%RUN_V842_CONTROLLER_COMPARISON Baselines vs Full Safe-SAC.

if nargin < 3 || isempty(mode)
    mode = 'base';
end
controllers = { ...
    'Full Safe-SAC v8.4.2', 'sac';
    'No battery', 'no battery';
    'Greedy VPP tracking', 'greedy vpp tracking';
    'Rule-based DR/SOC', 'rule-based dr/soc';
    'TOU self-consumption', 'tou self-consumption'};

shieldFull = struct('enableSOC', true, 'enableRamp', true, 'enablePeakShield', true, ...
    'enableServiceShield', true, 'enableTerminalShield', true, 'enableEconCoach', true);
shieldNoBattery = struct('enableSOC', false, 'enableRamp', false, 'enablePeakShield', false, ...
    'enableServiceShield', false, 'enableTerminalShield', false, 'enableEconCoach', false);

S = cell(size(controllers,1), 1);
trajCell = cell(size(controllers,1), 1);
for i = 1:size(controllers,1)
    displayName = controllers{i,1};
    codeName = controllers{i,2};
    if strcmpi(codeName, 'sac')
        [summary, traj] = simulate_controller_v842(par, mode, codeName, sacAgent, shieldFull, par.eval.deterministicSeed);
    elseif strcmpi(codeName, 'no battery')
        [summary, traj] = simulate_controller_v842(par, mode, codeName, [], shieldNoBattery, par.eval.deterministicSeed);
    else
        [summary, traj] = simulate_controller_v842(par, mode, codeName, [], shieldFull, par.eval.deterministicSeed);
    end
    summary.Controller = string(displayName);
    S{i} = orderfields(summary);
    trajCell{i} = traj; %#ok<NASGU>
end

T = struct2table(vertcat(S{:}));
rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
save(fullfile(resultsDir, ['v842_controller_comparison_' char(mode) '.mat']), 'T', 'trajCell', 'par');
disp(T(:, {'Controller','DailyCost','ObjectiveValue','MaxGridImport','TerminalSOCError','VPPTrackingRMSE','DRSuccessRateFeasible','ActionClippedFraction','SoftCoachActionFraction'}));
end
