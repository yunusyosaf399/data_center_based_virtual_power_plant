function par = vpp_default_parameters_v842()
%VPP_DEFAULT_PARAMETERS_V842 Parameters for Safe-SAC VPP data-center v8.4.2.

par.version = 'v8.4.2';
par.rngSeed = 842;

% Time discretization
par.dtHours = 0.25;
par.stepsPerDay = round(24 / par.dtHours);
par.N = par.stepsPerDay;
par.tHours = (0:par.N-1)' * par.dtHours;

% Battery model
par.EbattKWh = 4000;
par.PbattMaxKW = 750;
par.etaCharge = 0.965;
par.etaDischarge = 0.965;
par.soc0 = 0.55;
par.socTarget = 0.55;
par.socMin = 0.30;
par.socMax = 0.90;
par.socReserveDR = 0.48;
par.socSoftLow = 0.38;
par.rampKWPerStep = 360;
par.emergencyRampKWPerStep = 760;

% Grid/VPP service
par.gridPeakLimitKW = 1500;
par.gridPeakSoftKW = 1460;
par.drImportLimitKW = 850;
par.drStartHour = 16.25;
par.drEndHour = 18.00;
par.drPrepHours = 3.0;
par.drHardPrepHours = 0.75;
par.gridRefSmoothingHours = 3.0;
par.trackingDeadbandKW = 20;

% Economic parameters
par.energyPriceBase = 0.11;
par.degradationCostPerKWh = 0.017;
par.exportPriceFactor = 0.10;

% Reward/objective equivalent weights. Objective is reported in $-equivalent.
par.wTrack = 0.00145;
par.wDR = 0.26;
par.wPeak = 0.09;
par.wRamp = 0.006;
par.wSocLow = 2.0e4;
par.wSocHigh = 2.0e4;
par.wTerminal = 2.2e4;
par.wTerminalLate = 5.0e4;
par.wReservePrep = 1.0e4;
par.wPolicyCoach = 0.0055;
par.wActionSmooth = 0.0010;
par.rewardScale = 110;


% v8.4.2 economic relaxation / hard-safety separation
par.trackPriceRelaxation = 0.72;      % lower VPP tracking weight in non-service economic windows
par.trackServiceBoost = 1.35;         % stronger tracking during DR and near hard caps
par.highPriceThreshold = 0.22;
par.lowPriceThreshold = 0.095;
par.econCoachBlend = 0.18;            % soft advisory; not counted as hard clipping
par.econChargeSOCMax = 0.60;
par.econDischargeSOCMin = 0.50;
par.econGridTargetKW = 1080;          % high-price import target before hard peak/DR caps
par.econLowPriceChargeKW = 180;
par.hardClipToleranceKW = 2.0;

% v8.4.2 shield tuning
par.shield.peakHardMarginKW = 3;
par.shield.drHardMarginKW = 4;
par.shield.peakSoftBufferKW = 20;
par.shield.serviceBlend = 0.60;
par.shield.prepBlend = 0.22;
par.shield.terminalBlend = 0.16;
par.shield.terminalHardSteps = 2;
par.shield.terminalSoftHours = 3.25;
par.shield.allowTerminalDuringDR = false;
par.shield.maxClipFractionTarget = 0.10;

% Training options
par.train.maxEpisodes = 1800;
par.train.maxStepsPerEpisode = par.N;
par.train.scoreAveragingWindowLength = 60;
par.train.stopAverageReward = -7.0;
par.train.saveAgentValue = -10.0;
par.train.miniBatchSize = 256;
par.train.experienceBufferLength = 2e6;
par.train.discountFactor = 0.995;
par.train.sampleTime = par.dtHours;
par.train.actorLearnRate = 2e-4;
par.train.criticLearnRate = 3e-4;
par.train.entropyWeight = 0.035;
par.train.curriculumMode = 'training';
par.train.stressEveryNEpisodes = 6;

% Evaluation options
par.eval.numStochasticScenarios = 150;
par.eval.numStressScenarios = 60;
par.eval.deterministicSeed = 84201;
par.eval.stochasticSeed0 = 9000;
par.eval.stressSeed0 = 12000;

% Plot options
par.plot.savePDF = false;
par.plot.fontSize = 13;
par.plot.lineWidth = 2.0;
end
