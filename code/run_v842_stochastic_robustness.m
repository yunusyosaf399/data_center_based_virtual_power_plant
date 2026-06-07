function T = run_v842_stochastic_robustness(sacAgent, par)
%RUN_V842_STOCHASTIC_ROBUSTNESS Monte Carlo robustness test.

n = par.eval.numStochasticScenarios;
S = cell(n, 1);
shieldFull = struct('enableSOC', true, 'enableRamp', true, 'enablePeakShield', true, ...
    'enableServiceShield', true, 'enableTerminalShield', true, 'enableEconCoach', true);
for i = 1:n
    seed = par.eval.stochasticSeed0 + i;
    [summary, ~] = simulate_controller_v842(par, 'stochastic', 'sac', sacAgent, shieldFull, seed);
    summary.Scenario = i;
    S{i} = orderfields(summary);
end
T = struct2table(vertcat(S{:}));
rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
save(fullfile(resultsDir, 'v842_stochastic_robustness.mat'), 'T', 'par');

fprintf('Scenarios: %d\n', n);
fprintf('Mean cost: %.1f $\n', mean(T.DailyCost));
fprintf('Mean terminal SOC error: %.3f\n', mean(T.TerminalSOCError));
fprintf('Mean tracking RMSE: %.1f kW\n', mean(T.VPPTrackingRMSE));
fprintf('Mean feasible DR success: %.1f %%\n', mean(T.DRSuccessRateFeasible, 'omitnan'));
end
