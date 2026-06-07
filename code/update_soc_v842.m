function socNext = update_soc_v842(soc, pBattKW, par)
%UPDATE_SOC_V842 One-step SOC update. Positive pBattKW = discharge.
dt = par.dtHours;
if pBattKW >= 0
    socNext = soc - (pBattKW / par.etaDischarge) * dt / par.EbattKWh;
else
    socNext = soc - (pBattKW * par.etaCharge) * dt / par.EbattKWh;
end
socNext = min(1.0, max(0.0, socNext));
end
