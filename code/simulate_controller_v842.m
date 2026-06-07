function [summary, traj] = simulate_controller_v842(par, mode, controllerName, agent, shieldOpts, seed)
%SIMULATE_CONTROLLER_V842 Simulates SAC or baseline controller.

if nargin < 2 || isempty(mode), mode = 'base'; end
if nargin < 3 || isempty(controllerName), controllerName = 'sac'; end
if nargin < 4, agent = []; end
if nargin < 5 || isempty(shieldOpts)
    shieldOpts = struct('enableSOC', true, 'enableRamp', true, 'enablePeakShield', true, ...
        'enableServiceShield', true, 'enableTerminalShield', true, 'enableEconCoach', true);
end
if nargin < 6 || isempty(seed)
    if strcmpi(mode, 'base')
        seed = par.eval.deterministicSeed;
    else
        seed = par.rngSeed;
    end
end

data = vpp_scenario_v842(par, mode, seed);
N = par.N;

soc = par.soc0;
lastP = 0;

traj = struct();
traj.tHours = data.tHours;
traj.loadKW = data.loadKW;
traj.pvKW = data.pvKW;
traj.netKW = data.netKW;
traj.price = data.price;
traj.gridRefKW = data.gridRefKW;
traj.drActive = data.drActive;
traj.drLimitKW = data.drLimitKW;
traj.soc = nan(N+1,1);
traj.soc(1) = soc;
traj.pRawKW = nan(N,1);
traj.pSafeKW = nan(N,1);
traj.pGridKW = nan(N,1);
traj.gridImportKW = nan(N,1);
traj.trackingErrKW = nan(N,1);
traj.rewardStep = nan(N,1);
traj.energyCost = nan(N,1);
traj.degradationCost = nan(N,1);
traj.objectiveStep = nan(N,1);
traj.trackingPenalty = nan(N,1);
traj.drPenalty = nan(N,1);
traj.reservePrepPenalty = nan(N,1);
traj.peakPenalty = nan(N,1);
traj.rampPenalty = nan(N,1);
traj.socRecoveryPenalty = nan(N,1);
traj.postDRRecoveryPenalty = nan(N,1);
traj.socRiskPenalty = nan(N,1);
traj.terminalPenalty = nan(N,1);
traj.clipped = false(N,1);
traj.hardClipped = false(N,1);
traj.softCoachAction = false(N,1);
traj.economicCoachAction = false(N,1);
traj.serviceShieldAction = false(N,1);
traj.terminalShieldAction = false(N,1);
traj.peakShieldAction = false(N,1);
traj.lbKW = nan(N,1);
traj.ubKW = nan(N,1);

for k = 1:N
    obs = build_observation_for_policy_v842(k, soc, lastP, par, data);
    a = controller_action_v842(controllerName, obs, k, soc, lastP, par, data, agent);
    pRaw = a * par.PbattMaxKW;
    [pSafe, info] = safety_filter_v842(pRaw, soc, lastP, k, par, data, shieldOpts);
    socNext = update_soc_v842(soc, pSafe, par);
    m = compute_step_metrics_v842(pSafe, soc, socNext, lastP, k, par, data);

    traj.soc(k) = soc;
    traj.soc(k+1) = socNext;
    traj.pRawKW(k) = pRaw;
    traj.pSafeKW(k) = pSafe;
    traj.pGridKW(k) = m.pGridKW;
    traj.gridImportKW(k) = m.gridImportKW;
    traj.trackingErrKW(k) = m.trackingErrKW;
    traj.energyCost(k) = m.energyCost;
    traj.degradationCost(k) = m.degradationCost;
    traj.objectiveStep(k) = m.objectiveStep;
    traj.trackingPenalty(k) = m.trackingPenalty;
    traj.drPenalty(k) = m.drPenalty;
    traj.reservePrepPenalty(k) = m.reservePrepPenalty;
    traj.peakPenalty(k) = m.peakPenalty;
    traj.rampPenalty(k) = m.rampPenalty;
    traj.socRecoveryPenalty(k) = m.socRecoveryPenalty;
    traj.postDRRecoveryPenalty(k) = m.postDRRecoveryPenalty;
    traj.socRiskPenalty(k) = m.socRiskPenalty;
    traj.terminalPenalty(k) = m.terminalPenalty;
    traj.clipped(k) = info.clipped;
    if isfield(info, 'hardClipped'), traj.hardClipped(k) = info.hardClipped; end
    if isfield(info, 'softCoachAction'), traj.softCoachAction(k) = info.softCoachAction; end
    if isfield(info, 'economicCoachAction'), traj.economicCoachAction(k) = info.economicCoachAction; end
    traj.serviceShieldAction(k) = info.serviceShieldAction;
    traj.terminalShieldAction(k) = info.terminalShieldAction;
    traj.peakShieldAction(k) = info.peakShieldAction;
    traj.lbKW(k) = info.lbKW;
    traj.ubKW(k) = info.ubKW;

    soc = socNext;
    lastP = pSafe;
end

summary = summarize_trajectory_v842(traj, par, data, controllerName, mode, seed);
end
