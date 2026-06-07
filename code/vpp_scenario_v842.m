function data = vpp_scenario_v842(par, mode, seed)
%VPP_SCENARIO_V842 Generates deterministic, stochastic, or combined-stress daily profiles.

if nargin < 2 || isempty(mode)
    mode = 'base';
end
if nargin < 3 || isempty(seed)
    seed = par.rngSeed;
end
rng(seed, 'twister');

N = par.N;
t = par.tHours(:);
dt = par.dtHours;

% Data-center AI load: base compute demand + training bursts + stochastic jitter.
baseLoad = 1030 + 90*sin(2*pi*(t-2)/24) + 55*sin(4*pi*(t+1)/24);
trainPulse = zeros(N,1);
trainPulse = trainPulse + 120*exp(-0.5*((t-5.4)/0.9).^2);
trainPulse = trainPulse + 180*exp(-0.5*((t-15.4)/1.0).^2);
trainPulse = trainPulse - 190*exp(-0.5*((t-10.2)/1.2).^2);
loadKW = baseLoad + trainPulse;

% On-site PV.
pvShape = max(0, sin(pi*(t-6.2)/12.4)).^1.55;
pvKW = 980 * pvShape;
cloud = 1 - 0.18*exp(-0.5*((t-14.3)/1.2).^2);
pvKW = pvKW .* cloud;

% TOU price.
price = par.energyPriceBase * ones(N,1);
price(t >= 6 & t < 10) = 0.16;
price(t >= 15 & t < 20) = 0.26;
price(t >= 20 & t < 23) = 0.18;
price(t >= 10 & t < 15) = 0.08;

% VPP grid reference: smoothed grid import request with DR event.
net = loadKW - pvKW;
win = max(3, round(par.gridRefSmoothingHours/dt));
gridRef = movmean(net, win, 'Endpoints', 'shrink');
gridRef = gridRef - 130*exp(-0.5*((t-10.0)/1.4).^2);
gridRef = min(gridRef, par.gridPeakSoftKW);

% DR active interval and import limit.
drActive = (t >= par.drStartHour & t < par.drEndHour);
drLimit = inf(N,1);
drLimit(drActive) = par.drImportLimitKW;
gridRef(drActive) = min(gridRef(drActive), par.drImportLimitKW - 25);

modeLower = lower(string(mode));
if modeLower == "stochastic" || modeLower == "random"
    loadKW = loadKW .* (1 + 0.055*randn(N,1));
    pvKW = max(0, pvKW .* (1 + 0.11*randn(N,1)));
    price = max(0.03, price .* (1 + 0.10*randn(N,1)));
    gridRef = gridRef + 35*randn(N,1);
elseif modeLower == "stress" || modeLower == "combined-stress" || modeLower == "combined_stress"
    loadKW = 1.20*loadKW + 120*exp(-0.5*((t-15.8)/0.5).^2);
    pvKW = 0.72*pvKW;
    price(t >= 15 & t < 20) = 0.32;
    gridRef = gridRef + 70*sin(2*pi*(t-3)/24) + 70*randn(N,1);
    % Harder VPP event: longer and lower import cap.
    drActive = (t >= 16.10 & t < 18.05);
    drLimit = inf(N,1);
    drLimit(drActive) = par.drImportLimitKW - 20;
    gridRef(drActive) = min(gridRef(drActive), par.drImportLimitKW - 50);
elseif modeLower == "highpv"
    pvKW = 1.25*pvKW;
elseif modeLower == "lowpv"
    pvKW = 0.65*pvKW;
end

loadKW = max(250, loadKW);
pvKW = max(0, pvKW);
net = loadKW - pvKW;
gridRef = max(-250, min(par.gridPeakSoftKW, gridRef));

% Forecasts: imperfect short-horizon forecasts used in observation only.
forecastH = 4;
loadForecast = zeros(N, forecastH);
pvForecast = zeros(N, forecastH);
priceForecast = zeros(N, forecastH);
for h = 1:forecastH
    idx = min(N, (1:N)' + h);
    loadForecast(:,h) = loadKW(idx) .* (1 + 0.018*randn(N,1));
    pvForecast(:,h) = max(0, pvKW(idx) .* (1 + 0.040*randn(N,1)));
    priceForecast(:,h) = price(idx);
end

% DR lookahead features.
drUpcoming = false(N,1);
timeToDRStart = inf(N,1);
drRemaining = zeros(N,1);
for k = 1:N
    tk = t(k);
    if tk < par.drStartHour && par.drStartHour - tk <= par.drPrepHours
        drUpcoming(k) = true;
        timeToDRStart(k) = par.drStartHour - tk;
    end
    if drActive(k)
        drRemaining(k) = max(0, par.drEndHour - tk);
    end
end

% Normalizers kept with data for consistent observation scaling.
data.tHours = t;
data.loadKW = loadKW;
data.pvKW = pvKW;
data.netKW = net;
data.price = price;
data.gridRefKW = gridRef;
data.drActive = drActive;
data.drUpcoming = drUpcoming;
data.drLimitKW = drLimit;
data.timeToDRStartH = timeToDRStart;
data.drRemainingH = drRemaining;
data.loadForecastKW = loadForecast;
data.pvForecastKW = pvForecast;
data.priceForecast = priceForecast;
data.mode = char(mode);
data.seed = seed;
data.normLoadKW = max(1500, prctile(loadKW, 95));
data.normNetKW = max(1500, prctile(abs(net), 95));
data.normPrice = max(0.30, max(price));
end
