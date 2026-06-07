function plot_v842_all_results(par)
%PLOT_V842_ALL_RESULTS Publication figures for v8.4.2.

if nargin < 1 || isempty(par), par = vpp_default_parameters_v842(); end
rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
figDir = fullfile(rootDir, 'figures');
if ~exist(figDir, 'dir'), mkdir(figDir); end

S = load(fullfile(resultsDir, 'v842_deterministic_eval.mat'), 'summary', 'traj');
summary = S.summary;
traj = S.traj;

plot_vpp_tracking_v842(traj, summary, par);
plot_safety_filter_v842(traj, par);
plot_terminal_soc_v842(traj, summary, par);
plot_objective_decomp_v842(traj, par);
plot_duration_curve_v842(traj, summary, par);
plot_summary_table_v842(summary, par);
plot_fast_smoothing_demo_v842(par);
plot_hierarchical_ess_v842(par);
plot_publication_architecture_v842(par);

if exist(fullfile(resultsDir, 'v842_stochastic_robustness.mat'), 'file')
    R = load(fullfile(resultsDir, 'v842_stochastic_robustness.mat'), 'T');
    plot_stochastic_boxplots_v842(R.T, par);
end
if exist(fullfile(resultsDir, 'v842_controller_comparison_base.mat'), 'file')
    C = load(fullfile(resultsDir, 'v842_controller_comparison_base.mat'), 'T');
    plot_controller_table_v842(C.T, 'v8.4.2 deterministic controller comparison', 'fig12_controller_baseline_comparison', par);
end
if exist(fullfile(resultsDir, 'v842_combined_stress_controller_comparison.mat'), 'file')
    C = load(fullfile(resultsDir, 'v842_combined_stress_controller_comparison.mat'), 'T');
    plot_controller_table_v842(C.T, 'v8.4.2 combined-stress controller comparison', 'fig13_combined_stress_controller_comparison', par);
end
fprintf('v8.4.2 figures saved to %s\n', figDir);
end

function plot_vpp_tracking_v842(traj, summary, par)
fig = figure('Name','v8.4.2 VPP tracking and DR response', 'Position',[100 100 1400 760]);
subplot(2,1,1);
hold on; grid on; box on;
yl = [-500 2000];
dr = traj.drActive;
if any(dr)
    x1 = min(traj.tHours(dr)); x2 = max(traj.tHours(dr))+par.dtHours;
    patch([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], [0.9 0.9 0.9], 'EdgeColor','none', 'FaceAlpha',0.45);
end
plot(traj.tHours, traj.gridRefKW, 'k--', 'LineWidth', par.plot.lineWidth);
plot(traj.tHours, traj.pGridKW, 'LineWidth', par.plot.lineWidth);
plot(traj.tHours, par.gridPeakLimitKW*ones(size(traj.tHours)), ':', 'LineWidth', par.plot.lineWidth);
ylabel('Grid power [kW]');
title('v8.4.2 VPP grid-service tracking and demand-response compliance');
legend('DR event','P_{grid,ref}','P_{grid}','Peak/DR import limit', 'Location','best');
ylim(yl);

subplot(2,1,2);
plot(traj.tHours, traj.trackingErrKW, 'LineWidth', par.plot.lineWidth); grid on; box on;
yline(0, 'k--');
ylabel('Tracking error [kW]'); xlabel('Time [h]');
title(sprintf('Tracking RMSE = %.1f kW, DR success = %.1f%%, feasible DR success = %.1f%%', ...
    summary.VPPTrackingRMSE, summary.DRSuccessRate, summary.DRSuccessRateFeasible));
save_figure_v842(fig, 'fig01_vpp_tracking_dr_response', par);
end

function plot_safety_filter_v842(traj, par)
fig = figure('Name','v8.4.2 safety filter', 'Position',[100 100 1400 760]);
subplot(2,1,1);
hold on; grid on; box on;
plot(traj.tHours, traj.pRawKW, 'LineWidth', 1.6);
plot(traj.tHours, traj.pSafeKW, 'LineWidth', par.plot.lineWidth+0.5);
plot(traj.tHours, traj.ubKW, 'k--', 'LineWidth', 1.3);
plot(traj.tHours, traj.lbKW, 'k--', 'LineWidth', 1.3);
ylabel('Battery power [kW]');
title('v8.4.2 SAC raw action projected into safe battery operating region');
legend('Raw SAC command','Safe applied command','Safe upper/lower bounds', 'Location','best');
subplot(2,1,2);
stairs(traj.tHours, double(traj.clipped), 'LineWidth', par.plot.lineWidth); hold on;
if isfield(traj, 'softCoachAction')
    stairs(traj.tHours, 0.5*double(traj.softCoachAction), '--', 'LineWidth', 1.2);
    legend('Hard safety clipping','Soft coach advisory', 'Location','best');
end
grid on; box on;
ylabel('Intervention'); xlabel('Time [h]'); ylim([-0.1 1.1]);
title(sprintf('Hard safety clipping fraction = %.1f%%', 100*mean(traj.clipped)));
save_figure_v842(fig, 'fig02_safety_filter_raw_vs_safe_action', par);
end

function plot_terminal_soc_v842(traj, summary, par)
fig = figure('Name','v8.4.2 SOC and flexibility', 'Position',[100 100 1400 900]);
subplot(3,1,1);
plot([traj.tHours; traj.tHours(end)+par.dtHours], traj.soc, 'LineWidth', par.plot.lineWidth); grid on; box on; hold on;
yline(par.socMax, 'k--', 'SOC max');
yline(par.socMin, 'r--', 'Reserve SOC');
yline(par.socTarget, 'b:', 'Initial/target SOC');
ylabel('SOC [-]'); ylim([0.2 1.0]);
title(sprintf('Terminal SOC fairness: |SOC_N - SOC_0| = %.3f', summary.TerminalSOCError));
subplot(3,1,2);
up = min(par.PbattMaxKW, max(0, (traj.soc(1:end-1)-par.socMin)*par.EbattKWh*par.etaDischarge/par.dtHours));
dn = min(par.PbattMaxKW, max(0, (par.socMax-traj.soc(1:end-1))*par.EbattKWh/(par.etaCharge*par.dtHours)));
plot(traj.tHours, up, 'LineWidth', par.plot.lineWidth); hold on; grid on; box on;
plot(traj.tHours, dn, 'LineWidth', par.plot.lineWidth);
ylabel('Flexibility [kW]');
title('Available upward/downward VPP flexibility from battery state');
legend('Upward flexibility: discharge potential','Downward flexibility: charge potential', 'Location','best');
subplot(3,1,3);
plot(traj.tHours, abs(traj.pSafeKW), 'LineWidth', par.plot.lineWidth); grid on; box on;
ylabel('|P_{batt}| [kW]'); xlabel('Time [h]');
title(sprintf('Battery throughput = %.1f kWh, EFC = %.3f', summary.BatteryThroughput, summary.EFC));
save_figure_v842(fig, 'fig03_terminal_soc_and_flexibility_envelope', par);
end

function plot_objective_decomp_v842(traj, par)
fig = figure('Name','v8.4.2 objective decomposition', 'Position',[100 100 1350 760]);
X = traj.tHours;
Y = [traj.energyCost traj.degradationCost traj.trackingPenalty traj.drPenalty traj.reservePrepPenalty ...
     traj.peakPenalty traj.rampPenalty traj.socRecoveryPenalty traj.postDRRecoveryPenalty traj.socRiskPenalty traj.terminalPenalty];
area(X, Y, 'LineStyle','none'); grid on; box on;
ylabel('Objective contribution [$ or penalty equivalent]'); xlabel('Time [h]');
title('v8.4.2 Safe-SAC objective decomposition: cost, degradation, VPP service, ramping, SOC, terminal fairness');
legend({'Energy cost','Battery degradation','VPP tracking','DR violation','DR reserve prep','Peak import', ...
    'Ramp penalty','SOC recovery','Post-DR recovery','SOC risk','Terminal SOC'}, 'Location','eastoutside');
save_figure_v842(fig, 'fig04_objective_reward_decomposition', par);
end

function plot_duration_curve_v842(traj, summary, par)
fig = figure('Name','v8.4.2 duration curve', 'Position',[100 100 1350 720]);
importSorted = sort(traj.gridImportKW, 'descend');
percent = 100*(1:numel(importSorted))/numel(importSorted);
plot(percent, importSorted, 'LineWidth', par.plot.lineWidth+0.5); grid on; box on;
ylabel('Grid import [kW]'); xlabel('Percent of day exceeded [%]');
title(sprintf('v8.4.2 grid-import duration curve: peak import = %.1f kW, import energy = %.1f kWh', ...
    summary.MaxGridImport, summary.ImportedEnergy));
save_figure_v842(fig, 'fig05_grid_import_duration_curve', par);
end

function plot_stochastic_boxplots_v842(T, par)
fig = figure('Name','v8.4.2 stochastic robustness', 'Position',[100 100 1400 800]);
subplot(2,3,1); boxplot(T.DailyCost); title('Daily cost'); ylabel('Cost [$]'); grid on;
subplot(2,3,2); boxplot(T.MaxGridImport); title('Peak grid import'); ylabel('Peak import [kW]'); grid on;
subplot(2,3,3); boxplot(T.TerminalSOCError); title('Terminal SOC error'); ylabel('|SOC_N-SOC_0|'); grid on;
subplot(2,3,4); boxplot(T.VPPTrackingRMSE); title('VPP tracking RMSE'); ylabel('RMSE [kW]'); grid on;
subplot(2,3,5); boxplot(T.DRSuccessRateFeasible); title('Feasible demand-response success'); ylabel('DR success [%]'); grid on;
subplot(2,3,6); axis off;
text(0.05,0.80,sprintf('Scenarios: %d', height(T)), 'FontSize', 14);
text(0.05,0.62,sprintf('Mean cost: %.1f $', mean(T.DailyCost)), 'FontSize', 14);
text(0.05,0.44,sprintf('Mean terminal SOC error: %.3f', mean(T.TerminalSOCError)), 'FontSize', 14);
text(0.05,0.26,sprintf('Mean tracking RMSE: %.1f kW', mean(T.VPPTrackingRMSE)), 'FontSize', 14);
text(0.05,0.08,sprintf('Mean feasible DR success: %.1f %%', mean(T.DRSuccessRateFeasible, 'omitnan')), 'FontSize', 14);
save_figure_v842(fig, 'fig06_stochastic_robustness_boxplots', par);
end

function plot_summary_table_v842(summary, par)
fig = figure('Name','v8.4.2 summary table', 'Position',[100 100 1100 900]);
axis off;
title('v8.4.2 Safe-SAC deterministic evaluation summary', 'FontSize', 24, 'FontWeight','bold');
labels = {'Daily operating cost [$]','Objective value [$ + penalties]','Max grid import [kW]', ...
    'Imported energy [kWh]','Battery throughput [kWh]','Final SOC [-]','Terminal SOC error [-]', ...
    'VPP tracking RMSE [kW]','DR success rate [%]','Feasible DR success [%]', ...
    'Hard clipped [%]','Soft coach [%]','Peak penalty','SOC recovery penalty','Post-DR recovery penalty'};
vals = [summary.DailyCost, summary.ObjectiveValue, summary.MaxGridImport, summary.ImportedEnergy, ...
    summary.BatteryThroughput, summary.FinalSOC, summary.TerminalSOCError, summary.VPPTrackingRMSE, ...
    summary.DRSuccessRate, summary.DRSuccessRateFeasible, summary.ActionClippedFraction, ...
    get_summary_field_v842(summary,'SoftCoachActionFraction',NaN), summary.PeakPenalty, summary.SOCRecoveryPenalty, summary.PostDRRecoveryPenalty];
y = 0.88;
for i = 1:numel(labels)
    text(0.07, y, labels{i}, 'FontSize', 18);
    text(0.78, y, sprintf('%.4g', vals(i)), 'FontSize', 18, 'FontWeight','bold');
    y = y - 0.055;
end
save_figure_v842(fig, 'fig07_publication_summary_table', par);
end

function val = get_summary_field_v842(summary, name, defaultVal)
if isfield(summary, name) && ~isempty(summary.(name))
    val = summary.(name);
else
    val = defaultVal;
end
end

function plot_controller_table_v842(T, plotTitle, fileBase, par)
fig = figure('Name', plotTitle, 'Position',[50 100 1700 620]);
axis off;
title(plotTitle, 'FontSize', 24, 'FontWeight','bold');
cols = {'Controller','DailyCost','ObjectiveValue','MaxGridImport','TerminalSOCError','VPPTrackingRMSE','DRSuccessRateFeasible','ActionClippedFraction'};
x = [0.01 0.18 0.34 0.50 0.64 0.76 0.88 0.97];
headers = {'Controller','DailyCost [$]','ObjectiveValue','MaxGridImport [kW]','TerminalSOCError [%]','VPPTrackingRMSE [kW]','FeasibleDRSuccess [%]','ActionClipped [%]'};
for j = 1:numel(headers)
    text(x(j),0.88,headers{j},'FontSize',14,'FontWeight','bold');
end
y = 0.76;
for i = 1:height(T)
    text(x(1), y, char(T.Controller(i)), 'FontSize', 14);
    text(x(2), y, sprintf('%.0f', T.DailyCost(i)), 'FontSize', 14);
    text(x(3), y, sprintf('%.0f', T.ObjectiveValue(i)), 'FontSize', 14);
    text(x(4), y, sprintf('%.0f', T.MaxGridImport(i)), 'FontSize', 14);
    text(x(5), y, sprintf('%.2f', 100*T.TerminalSOCError(i)), 'FontSize', 14);
    text(x(6), y, sprintf('%.1f', T.VPPTrackingRMSE(i)), 'FontSize', 14);
    if isnan(T.DRSuccessRateFeasible(i))
        drtxt = 'NaN';
    else
        drtxt = sprintf('%.1f', T.DRSuccessRateFeasible(i));
    end
    text(x(7), y, drtxt, 'FontSize', 14);
    text(x(8), y, sprintf('%.2f', T.ActionClippedFraction(i)), 'FontSize', 14);
    y = y - 0.12;
end
save_figure_v842(fig, fileBase, par);
end
