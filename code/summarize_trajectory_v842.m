function summary = summarize_trajectory_v842(traj, par, data, controllerName, mode, seed)
%SUMMARIZE_TRAJECTORY_V842 Calculates publication metrics.

dt = par.dtHours;
drIdx = data.drActive(:);
finiteDR = isfinite(data.drLimitKW(:));
drIdx = drIdx & finiteDR;

if any(drIdx)
    drOK = traj.pGridKW(drIdx) <= data.drLimitKW(drIdx) + 1e-6;
    drSuccess = 100 * mean(drOK);
    feasibleDRSuccess = drSuccess;
    drFeasibleFraction = 100;
else
    drSuccess = NaN;
    feasibleDRSuccess = NaN;
    drFeasibleFraction = NaN;
end

summary = struct();
summary.Controller = string(controllerName);
summary.Mode = string(mode);
summary.Seed = seed;
summary.DailyCost = sum(traj.energyCost);
summary.ObjectiveValue = sum(traj.objectiveStep);
summary.MaxGridImport = max(traj.gridImportKW);
summary.ImportedEnergy = sum(traj.gridImportKW) * dt;
summary.BatteryThroughput = sum(abs(traj.pSafeKW)) * dt;
summary.EFC = summary.BatteryThroughput/(2*par.EbattKWh);
summary.FinalSOC = traj.soc(end);
summary.TerminalSOCError = abs(traj.soc(end) - par.socTarget);
summary.VPPTrackingRMSE = sqrt(mean((traj.pGridKW - data.gridRefKW).^2));
summary.DRSuccessRate = drSuccess;
summary.DRSuccessRateFeasible = feasibleDRSuccess;
summary.DRFeasibleFraction = drFeasibleFraction;
summary.DRReservePrepPenalty = sum(traj.reservePrepPenalty);
summary.PeakPenalty = sum(traj.peakPenalty);
summary.SOCRecoveryPenalty = sum(traj.socRecoveryPenalty);
summary.PostDRRecoveryPenalty = sum(traj.postDRRecoveryPenalty);
summary.SOCRiskPenalty = sum(traj.socRiskPenalty);
summary.TerminalSOCPenalty = sum(traj.terminalPenalty);
summary.ActionClippedFraction = 100 * mean(traj.clipped);
if isfield(traj, 'hardClipped'), summary.HardClipFraction = 100 * mean(traj.hardClipped); else, summary.HardClipFraction = summary.ActionClippedFraction; end
if isfield(traj, 'softCoachAction'), summary.SoftCoachActionFraction = 100 * mean(traj.softCoachAction); else, summary.SoftCoachActionFraction = NaN; end
if isfield(traj, 'economicCoachAction'), summary.EconomicCoachActionFraction = 100 * mean(traj.economicCoachAction); else, summary.EconomicCoachActionFraction = NaN; end
summary.ServiceShieldActionFraction = 100 * mean(traj.serviceShieldAction);
summary.TerminalShieldActionFraction = 100 * mean(traj.terminalShieldAction);
summary.PeakShieldActionFraction = 100 * mean(traj.peakShieldAction);
summary.GridPeakViolationKWh = sum(max(0, traj.pGridKW - par.gridPeakLimitKW)) * dt;
if any(drIdx)
    summary.DRViolationKWh = sum(max(0, traj.pGridKW(drIdx) - data.drLimitKW(drIdx))) * dt;
else
    summary.DRViolationKWh = 0;
end
end
