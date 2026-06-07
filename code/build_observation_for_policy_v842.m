function obs = build_observation_for_policy_v842(k, soc, lastPbatKW, par, data)
%BUILD_OBSERVATION_FOR_POLICY_V842 Standalone observation builder used by simulations.

k = max(1, min(par.N, k));
net = data.netKW(k);
upwardFlex = min(par.PbattMaxKW, max(0, (soc - par.socMin)*par.EbattKWh*par.etaDischarge/par.dtHours));
downwardFlex = min(par.PbattMaxKW, max(0, (par.socMax - soc)*par.EbattKWh/(par.etaCharge*par.dtHours)));
peakHeadroom = par.gridPeakLimitKW - (net - lastPbatKW);
terminalNeed = par.socTarget - soc;
h2 = min(size(data.priceForecast,2), 2);

obs = zeros(22,1);
obs(1) = 2*(soc - 0.5);
obs(2) = (k-1)/(par.N-1);
obs(3) = sin(2*pi*data.tHours(k)/24);
obs(4) = cos(2*pi*data.tHours(k)/24);
obs(5) = data.price(k)/data.normPrice;
obs(6) = data.loadKW(k)/data.normLoadKW;
obs(7) = data.pvKW(k)/max(1, data.normLoadKW);
obs(8) = net/data.normNetKW;
obs(9) = data.gridRefKW(k)/data.normNetKW;
obs(10) = double(data.drActive(k));
obs(11) = double(data.drUpcoming(k));
obs(12) = min(1, data.timeToDRStartH(k)/max(par.drPrepHours, par.dtHours));
if isinf(obs(12)), obs(12) = 1; end
obs(13) = min(1, data.drRemainingH(k)/max(1, par.drEndHour-par.drStartHour));
obs(14) = min(2, data.drLimitKW(k)/par.gridPeakLimitKW);
if isinf(obs(14)), obs(14) = 1; end
obs(15) = upwardFlex/par.PbattMaxKW;
obs(16) = downwardFlex/par.PbattMaxKW;
obs(17) = terminalNeed;
obs(18) = peakHeadroom/par.gridPeakLimitKW;
obs(19) = lastPbatKW/par.PbattMaxKW;
obs(20) = (data.loadForecastKW(k,1)-data.pvForecastKW(k,1))/data.normNetKW;
obs(21) = (mean(data.loadForecastKW(k,:)) - data.loadKW(k))/data.normLoadKW;
obs(22) = mean(data.priceForecast(k,1:h2))/data.normPrice;
obs = max(-5, min(5, obs));
end
