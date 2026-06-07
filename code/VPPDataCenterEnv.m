classdef VPPDataCenterEnv < rl.env.MATLABEnvironment
    %VPPDATACENTERENV Safe-SAC VPP data-center battery dispatch environment.
    % Observation: 22 x 1 normalized state vector.
    % Action: scalar in [-1, 1], mapped to battery power command.

    properties
        par
        mode
        Data
        StepIndex
        SOC
        LastPbatKW
        EpisodeCounter
        ShieldOptions
        LastInfo
        LastMetrics
    end

    methods
        function this = VPPDataCenterEnv(par, mode, shieldOptions)
            if nargin < 2 || isempty(mode)
                mode = 'base';
            end
            if nargin < 3 || isempty(shieldOptions)
                shieldOptions = struct();
            end

            obsInfo = rlNumericSpec([22 1], 'LowerLimit', -5*ones(22,1), 'UpperLimit', 5*ones(22,1));
            obsInfo.Name = 'vpp_datacenter_observation';
            obsInfo.Description = 'SOC, forecasts, prices, VPP reference, DR lookahead, flexibility';

            actInfo = rlNumericSpec([1 1], 'LowerLimit', -1, 'UpperLimit', 1);
            actInfo.Name = 'normalized_battery_power';
            actInfo.Description = 'Battery power command normalized to +/- Pmax';

            this = this@rl.env.MATLABEnvironment(obsInfo, actInfo);
            this.par = par;
            this.mode = mode;
            this.ShieldOptions = shieldOptions;
            this.EpisodeCounter = 0;
            reset(this);
        end

        function obs = reset(this)
            this.EpisodeCounter = this.EpisodeCounter + 1;
            if strcmpi(this.mode, 'base')
                seed = this.par.eval.deterministicSeed;
                scenarioMode = 'base';
            elseif strcmpi(this.mode, 'training')
                seed = this.par.rngSeed + 97*this.EpisodeCounter;
                if mod(this.EpisodeCounter, this.par.train.stressEveryNEpisodes) == 0
                    scenarioMode = 'combined-stress';
                elseif mod(this.EpisodeCounter, 5) == 0
                    scenarioMode = 'lowpv';
                elseif mod(this.EpisodeCounter, 7) == 0
                    scenarioMode = 'highpv';
                else
                    scenarioMode = 'stochastic';
                end
            else
                seed = this.par.rngSeed + 97*this.EpisodeCounter;
                scenarioMode = this.mode;
            end
            this.Data = vpp_scenario_v842(this.par, scenarioMode, seed);
            this.StepIndex = 1;
            this.SOC = this.par.soc0;
            this.LastPbatKW = 0;
            this.LastInfo = struct();
            this.LastMetrics = struct();
            obs = buildObservation(this);
        end

        function [obs, reward, isDone, loggedSignals] = step(this, action)
            if iscell(action)
                action = action{1};
            end
            if isa(action, 'dlarray')
                action = extractdata(action);
            end
            action = double(action(1));
            action = max(-1, min(1, action));
            pRawKW = action * this.par.PbattMaxKW;

            k = this.StepIndex;
            [pSafeKW, info] = safety_filter_v842(pRawKW, this.SOC, this.LastPbatKW, k, this.par, this.Data, this.ShieldOptions);
            socNext = update_soc_v842(this.SOC, pSafeKW, this.par);
            metrics = compute_step_metrics_v842(pSafeKW, this.SOC, socNext, this.LastPbatKW, k, this.par, this.Data);

            % Policy coach: train actor to anticipate shield actions instead of relying on projection.
            coachPenalty = this.par.wPolicyCoach * (pRawKW - info.coachKW)^2;
            smoothPenalty = this.par.wActionSmooth * (pSafeKW - this.LastPbatKW)^2;
            reward = -(metrics.objectiveStep + coachPenalty + smoothPenalty) / this.par.rewardScale;

            this.SOC = socNext;
            this.LastPbatKW = pSafeKW;
            this.LastInfo = info;
            this.LastMetrics = metrics;
            this.StepIndex = this.StepIndex + 1;
            isDone = this.StepIndex > this.par.N;

            if isDone
                obs = buildTerminalObservation(this);
            else
                obs = buildObservation(this);
            end

            loggedSignals = struct();
            loggedSignals.info = info;
            loggedSignals.metrics = metrics;
            loggedSignals.soc = socNext;
            loggedSignals.pBattKW = pSafeKW;
            loggedSignals.reward = reward;
        end

        function obs = buildObservation(this)
            k = max(1, min(this.par.N, this.StepIndex));
            obs = zeros(22,1);
            data = this.Data;
            par = this.par;
            soc = this.SOC;
            net = data.netKW(k);
            upwardFlex = min(par.PbattMaxKW, max(0, (soc - par.socMin)*par.EbattKWh*par.etaDischarge/par.dtHours));
            downwardFlex = min(par.PbattMaxKW, max(0, (par.socMax - soc)*par.EbattKWh/(par.etaCharge*par.dtHours)));
            peakHeadroom = par.gridPeakLimitKW - (net - this.LastPbatKW);
            terminalNeed = (par.socTarget - soc);
            h2 = min(size(data.priceForecast,2), 2);
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
            obs(19) = this.LastPbatKW/par.PbattMaxKW;
            obs(20) = (data.loadForecastKW(k,1)-data.pvForecastKW(k,1))/data.normNetKW;
            obs(21) = (mean(data.loadForecastKW(k,:)) - data.loadKW(k))/data.normLoadKW;
            obs(22) = mean(data.priceForecast(k,1:h2))/data.normPrice;
            obs = max(-5, min(5, obs));
        end

        function obs = buildTerminalObservation(this)
            savedStep = this.StepIndex;
            this.StepIndex = this.par.N;
            obs = buildObservation(this);
            this.StepIndex = savedStep;
        end
    end
end
