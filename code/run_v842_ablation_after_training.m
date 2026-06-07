function T = run_v842_ablation_after_training(sacAgent, par)
%RUN_V842_ABLATION_AFTER_TRAINING Tests contribution of service and terminal shields.

cases = { ...
    'SAC only, no shields', false, false, false, false, false, false; ...
    'SAC + peak/SOC/ramp shield', true, true, true, false, false, false; ...
    'SAC + DR service shield', true, true, true, true, false, false; ...
    'SAC + terminal SOC shield', true, true, true, false, true, false; ...
    'Full Safe-SAC v8.4.2', true, true, true, true, true, true};

S = cell(size(cases,1), 1);
for i = 1:size(cases,1)
    shieldOpts = struct('enableSOC', cases{i,2}, 'enableRamp', cases{i,3}, ...
        'enablePeakShield', cases{i,4}, 'enableServiceShield', cases{i,5}, ...
        'enableTerminalShield', cases{i,6}, 'enableEconCoach', cases{i,7});
    [summary, ~] = simulate_controller_v842(par, 'base', 'sac', sacAgent, shieldOpts, par.eval.deterministicSeed);
    summary.Case = string(cases{i,1});
    S{i} = orderfields(summary);
end
T = struct2table(vertcat(S{:}));
rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
save(fullfile(resultsDir, 'v842_ablation_table.mat'), 'T', 'par');
disp(T(:, {'Case','DailyCost','ObjectiveValue','MaxGridImport','TerminalSOCError','VPPTrackingRMSE','DRSuccessRateFeasible','ActionClippedFraction','ServiceShieldActionFraction','TerminalShieldActionFraction','SoftCoachActionFraction'}));
end
