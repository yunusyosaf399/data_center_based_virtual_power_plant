function m = compute_step_metrics_v842(pBattKW, soc, socNext, lastPbatKW, k, par, data)
%COMPUTE_STEP_METRICS_V842 Step-level objective components.

dt = par.dtHours;
netKW = data.netKW(k);
pGridKW = netKW - pBattKW;
gridImportKW = max(0, pGridKW);
gridExportKW = max(0, -pGridKW);
energyCost = (gridImportKW*data.price(k) - gridExportKW*data.price(k)*par.exportPriceFactor) * dt;
degradationCost = par.degradationCostPerKWh * abs(pBattKW) * dt;
trackingErrKW = pGridKW - data.gridRefKW(k);
trackEff = sign(trackingErrKW) * max(0, abs(trackingErrKW) - par.trackingDeadbandKW);

% v8.4.2: tariff-aware tracking weight. Outside active grid-service windows,
% the controller is allowed to trade a small tracking error for lower energy cost.
trackingWeight = par.wTrack;
if isfield(par, 'trackPriceRelaxation') && ~data.drActive(k) && ~data.drUpcoming(k) && ...
        (data.price(k) >= par.highPriceThreshold || data.price(k) <= par.lowPriceThreshold)
    trackingWeight = trackingWeight * par.trackPriceRelaxation;
end
if isfield(par, 'trackServiceBoost') && (data.drActive(k) || pGridKW > par.gridPeakSoftKW)
    trackingWeight = trackingWeight * par.trackServiceBoost;
end
trackingPenalty = trackingWeight * trackEff^2;

if data.drActive(k)
    drCap = min(data.drLimitKW(k), par.drImportLimitKW);
    drViolationKW = max(0, pGridKW - drCap);
else
    drViolationKW = 0;
end
drPenalty = par.wDR * drViolationKW^2;

peakViolationKW = max(0, pGridKW - par.gridPeakLimitKW);
peakPenalty = par.wPeak * peakViolationKW^2;

rampViolationKW = max(0, abs(pBattKW - lastPbatKW) - par.emergencyRampKWPerStep);
rampPenalty = par.wRamp * rampViolationKW^2;

socLowViolation = max(0, par.socMin - socNext);
socHighViolation = max(0, socNext - par.socMax);
socRiskPenalty = par.wSocLow*socLowViolation^2 + par.wSocHigh*socHighViolation^2;

reservePrepPenalty = 0;
if data.drUpcoming(k)
    reserveGap = max(0, par.socReserveDR - socNext);
    reservePrepPenalty = par.wReservePrep * reserveGap^2;
end

terminalPenalty = 0;
if k == par.N
    terminalPenalty = par.wTerminal * abs(socNext - par.socTarget)^2;
end

postDRRecoveryPenalty = 0;
if data.tHours(k) > par.drEndHour && data.tHours(k) <= par.drEndHour + 2.0
    postGap = max(0, par.socTarget - socNext);
    postDRRecoveryPenalty = 0.25*par.wTerminal * postGap^2;
end

socRecoveryPenalty = 0;
if socNext < par.socSoftLow
    socRecoveryPenalty = 0.15*par.wSocLow * (par.socSoftLow - socNext)^2;
end

objectiveStep = energyCost + degradationCost + trackingPenalty + drPenalty + peakPenalty + rampPenalty + ...
    socRiskPenalty + reservePrepPenalty + terminalPenalty + postDRRecoveryPenalty + socRecoveryPenalty;

m = struct();
m.pGridKW = pGridKW;
m.gridImportKW = gridImportKW;
m.gridExportKW = gridExportKW;
m.energyCost = energyCost;
m.degradationCost = degradationCost;
m.trackingErrKW = trackingErrKW;
m.trackingPenalty = trackingPenalty;
m.trackingWeight = trackingWeight;
m.drViolationKW = drViolationKW;
m.drPenalty = drPenalty;
m.peakViolationKW = peakViolationKW;
m.peakPenalty = peakPenalty;
m.rampViolationKW = rampViolationKW;
m.rampPenalty = rampPenalty;
m.socRiskPenalty = socRiskPenalty;
m.reservePrepPenalty = reservePrepPenalty;
m.terminalPenalty = terminalPenalty;
m.postDRRecoveryPenalty = postDRRecoveryPenalty;
m.socRecoveryPenalty = socRecoveryPenalty;
m.objectiveStep = objectiveStep;
end
