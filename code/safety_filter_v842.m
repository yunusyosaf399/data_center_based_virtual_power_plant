function [pSafe, info] = safety_filter_v842(pRawKW, soc, lastPbatKW, k, par, data, opts)
%SAFETY_FILTER_V842 Physics/VPP projection layer for v8.4.2.
%
% Positive P_batt means battery discharge. Negative P_batt means charging.
% The filter enforces SOC, ramp, peak cap, active DR cap, and late terminal SOC.

if nargin < 7 || isempty(opts)
    opts = struct();
end
opts = fill_opts(opts);

N = par.N;
k = max(1, min(N, k));
dt = par.dtHours;
netKW = data.netKW(k);

enableSOC = opts.enableSOC;
enableRamp = opts.enableRamp;
enablePeakShield = opts.enablePeakShield;
enableServiceShield = opts.enableServiceShield;
enableTerminalShield = opts.enableTerminalShield;
enableEconCoach = opts.enableEconCoach;

pRawKW = max(-par.PbattMaxKW, min(par.PbattMaxKW, pRawKW));

% 1) SOC energy feasibility bounds.
if enableSOC
    socFloor = par.socMin;
    if data.drActive(k) || data.drUpcoming(k)
        socFloor = max(socFloor, min(par.socReserveDR, par.socTarget + 0.04));
    end
    socCeil = par.socMax;
    maxDischargeBySOC = max(0, (soc - socFloor) * par.EbattKWh * par.etaDischarge / dt);
    maxChargeBySOC = max(0, (socCeil - soc) * par.EbattKWh / (par.etaCharge * dt));
    lb = -min(par.PbattMaxKW, maxChargeBySOC);
    ub =  min(par.PbattMaxKW, maxDischargeBySOC);
else
    lb = -par.PbattMaxKW;
    ub =  par.PbattMaxKW;
end

% 2) Ramp feasibility. Emergency ramp is allowed if violating peak/DR cap.
if enableRamp
    pNeedPeak = netKW - (par.gridPeakLimitKW - par.shield.peakHardMarginKW);
    pNeedDR = -inf;
    if data.drActive(k)
        pNeedDR = netKW - min(data.drLimitKW(k), par.drImportLimitKW) + par.shield.drHardMarginKW;
    end
    pNeed = max(pNeedPeak, pNeedDR);
    rampLimit = par.rampKWPerStep;
    if pNeed > lastPbatKW + par.rampKWPerStep
        rampLimit = par.emergencyRampKWPerStep;
    end
    lb = max(lb, lastPbatKW - rampLimit);
    ub = min(ub, lastPbatKW + rampLimit);
end

% 3) Peak import cap. P_grid = net - P_batt <= cap => P_batt >= net - cap.
peakLB = -inf;
if enablePeakShield
    peakLB = netKW - (par.gridPeakLimitKW - par.shield.peakHardMarginKW);
    lb = max(lb, peakLB);
end

% 4) Active DR service cap. This is intentionally hard during the DR window.
drLB = -inf;
if enableServiceShield && data.drActive(k)
    cap = min(data.drLimitKW(k), par.drImportLimitKW) - par.shield.drHardMarginKW;
    drLB = netKW - cap;
    lb = max(lb, drLB);
end

% 5) Soft economic advisory. This shifts the actor target in price-sensitive
% non-service intervals, but it is not counted as hard safety clipping.
pCoachKW = pRawKW;
econCoachAction = false;
if enableEconCoach && isfield(par, 'econCoachBlend') && par.econCoachBlend > 0 && ~data.drActive(k) && ~data.drUpcoming(k)
    pEconKW = pCoachKW;
    if data.price(k) >= par.highPriceThreshold && soc > par.econDischargeSOCMin
        % High-price hours: discharge only enough to reduce expensive import,
        % without draining below the economic SOC floor.
        pEconKW = min(par.PbattMaxKW, max(0, netKW - par.econGridTargetKW));
        maxEconDischarge = max(0, (soc - par.econDischargeSOCMin) * par.EbattKWh * par.etaDischarge / dt);
        pEconKW = min(pEconKW, maxEconDischarge);
    elseif data.price(k) <= par.lowPriceThreshold && soc < par.econChargeSOCMax && netKW < par.gridPeakSoftKW - 120
        % Low-price/PV-rich hours: small recharge, not full arbitrage. This keeps
        % v8.4.2 less conservative than v8.4.1 while avoiding high clipping.
        maxEconCharge = max(0, (par.econChargeSOCMax - soc) * par.EbattKWh / (par.etaCharge * dt));
        pEconKW = -min([par.PbattMaxKW, par.econLowPriceChargeKW, maxEconCharge]);
    end
    if abs(pEconKW - pCoachKW) > par.hardClipToleranceKW
        pCoachKW = (1 - par.econCoachBlend) * pCoachKW + par.econCoachBlend * pEconKW;
        econCoachAction = true;
    end
end

% 6) Pre-DR preparation. Prefer coach/blend instead of hard clipping.
if enableServiceShield && data.drUpcoming(k)
    timeToStart = max(dt, data.timeToDRStartH(k));
    desiredSOC = par.socReserveDR + 0.05*(1 - timeToStart/max(dt, par.drPrepHours));
    desiredSOC = min(par.socMax - 0.04, desiredSOC);
    if soc < desiredSOC
        pPrep = -min(par.PbattMaxKW, (desiredSOC - soc) * par.EbattKWh / (par.etaCharge * max(dt, timeToStart)));
        blend = par.shield.prepBlend;
        if timeToStart <= par.drHardPrepHours
            blend = min(0.75, 2*blend);
        end
        pCoachKW = (1 - blend)*pCoachKW + blend*pPrep;
    end
end

% 7) Terminal SOC glide. Late hard terminal control, but not during active DR.
terminalLB = -inf;
terminalUB = inf;
terminalStepsLeft = max(1, N - k + 1);
terminalHoursLeft = terminalStepsLeft * dt;
terminalActive = enableTerminalShield && terminalHoursLeft <= par.shield.terminalSoftHours;
if terminalActive
    terminalError = soc - par.socTarget;
    pTerminal = terminalError * par.EbattKWh / max(dt, terminalHoursLeft);
    pTerminal = max(-par.PbattMaxKW, min(par.PbattMaxKW, pTerminal));
    canUseTerminal = (~data.drActive(k)) || par.shield.allowTerminalDuringDR;
    if canUseTerminal
        pCoachKW = (1 - par.shield.terminalBlend)*pCoachKW + par.shield.terminalBlend*pTerminal;
        if terminalStepsLeft <= par.shield.terminalHardSteps
            tol = 0.006;
            if soc > par.socTarget + tol
                terminalLB = max(terminalLB, min(par.PbattMaxKW, 0.70*pTerminal));
                lb = max(lb, terminalLB);
            elseif soc < par.socTarget - tol
                terminalUB = min(terminalUB, max(-par.PbattMaxKW, 0.70*pTerminal));
                ub = min(ub, terminalUB);
            end
        end
    end
end

% 8) Projection. If bounds become inconsistent, prioritize SOC and cap with nearest feasible value.
if lb > ub
    if data.drActive(k) || peakLB > ub
        pProjected = ub;
    else
        pProjected = 0.5*(lb + ub);
    end
else
    pProjected = min(max(pCoachKW, lb), ub);
end

pSafe = max(-par.PbattMaxKW, min(par.PbattMaxKW, pProjected));

info = struct();
info.rawKW = pRawKW;
info.coachKW = pCoachKW;
info.safeKW = pSafe;
info.lbKW = lb;
info.ubKW = ub;
info.peakLBKW = peakLB;
info.drLBKW = drLB;
info.terminalLBKW = terminalLB;
info.terminalUBKW = terminalUB;
tolKW = max(1e-6, getfield_with_default(par, 'hardClipToleranceKW', 1.0));
hardClipped = (pRawKW < lb - tolKW) || (pRawKW > ub + tolKW) || (lb > ub);
softCoachAction = abs(pCoachKW - pRawKW) > tolKW;
info.clipped = hardClipped;
info.hardClipped = hardClipped;
info.softCoachAction = softCoachAction;
info.economicCoachAction = econCoachAction;
info.serviceShieldAction = enableServiceShield && (data.drActive(k) || data.drUpcoming(k)) && (hardClipped || softCoachAction);
info.terminalShieldAction = enableTerminalShield && terminalActive && (hardClipped || softCoachAction);
info.peakShieldAction = enablePeakShield && isfinite(peakLB) && pSafe >= peakLB - tolKW && hardClipped;
end

function val = getfield_with_default(s, fieldName, defaultVal)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    val = s.(fieldName);
else
    val = defaultVal;
end
end

function opts = fill_opts(opts)
fields = {'enableSOC','enableRamp','enablePeakShield','enableServiceShield','enableTerminalShield','enableEconCoach'};
defaults = {true,true,true,true,true,true};
for ii = 1:numel(fields)
    if ~isfield(opts, fields{ii}) || isempty(opts.(fields{ii}))
        opts.(fields{ii}) = defaults{ii};
    end
end
end
