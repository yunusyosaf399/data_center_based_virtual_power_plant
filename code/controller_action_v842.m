function actionNorm = controller_action_v842(controllerName, obs, k, soc, lastPbatKW, par, data, agent)
%CONTROLLER_ACTION_V842 Returns normalized raw action for SAC or baseline controller.
% Positive battery power means discharge.

name = lower(string(controllerName));
net = data.netKW(k);
pRaw = 0;

switch name
    case {"sac", "safe-sac", "full safe-sac", "full safe-sac v8.4.2", "agent"}
        if isempty(agent)
            pRaw = 0;
        else
            actionNorm = rl_get_action_numeric(agent, obs);
            return;
        end

    case {"no battery", "nobattery", "none"}
        pRaw = 0;

    case {"greedy", "greedy vpp", "greedy vpp tracking"}
        % Track VPP reference aggressively.
        pRaw = net - data.gridRefKW(k);

    case {"rule", "rule-based", "rule-based dr/soc", "rule_based"}
        % Conservative rule controller: preserve SOC, serve active DR, modest TOU arbitrage.
        if data.drActive(k)
            pRaw = net - min(data.drLimitKW(k), par.drImportLimitKW) + 15;
        elseif data.drUpcoming(k) && soc < par.socReserveDR + 0.03
            pRaw = -0.35*par.PbattMaxKW;
        elseif data.price(k) >= 0.22 && soc > par.socTarget + 0.03
            pRaw = 0.35*par.PbattMaxKW;
        elseif data.price(k) <= 0.09 && soc < par.socTarget + 0.08
            pRaw = -0.25*par.PbattMaxKW;
        else
            pRaw = 0.25*(net - data.gridRefKW(k));
        end

    case {"tou", "tou self-consumption", "self-consumption"}
        % Self-consumption / TOU controller: charge from PV/low price, discharge at high price.
        if data.price(k) <= 0.09 && soc < 0.80
            pRaw = -0.45*par.PbattMaxKW;
        elseif data.price(k) >= 0.22 && soc > par.socMin + 0.08
            pRaw = min(0.65*par.PbattMaxKW, max(0, net - 850));
        elseif net < 0 && soc < par.socMax - 0.03
            pRaw = max(-par.PbattMaxKW, net);
        else
            pRaw = 0;
        end

    otherwise
        error('Unknown controller name: %s', controllerName);
end

pRaw = max(-par.PbattMaxKW, min(par.PbattMaxKW, pRaw));
actionNorm = pRaw / par.PbattMaxKW;
actionNorm = max(-1, min(1, actionNorm));
end
