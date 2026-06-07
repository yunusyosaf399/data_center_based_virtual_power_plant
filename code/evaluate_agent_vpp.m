function [summary, traj] = evaluate_agent_vpp(agent, envOrMode, par, shieldOpts, seed)
%EVALUATE_AGENT_VPP Deterministic or scenario evaluation for SAC agent.

if nargin < 4 || isempty(shieldOpts)
    shieldOpts = struct('enableSOC', true, 'enableRamp', true, 'enablePeakShield', true, ...
        'enableServiceShield', true, 'enableTerminalShield', true, 'enableEconCoach', true);
end
if nargin < 5
    seed = [];
end

if isa(envOrMode, 'VPPDataCenterEnv')
    mode = envOrMode.mode;
else
    mode = envOrMode;
end

[summary, traj] = simulate_controller_v842(par, mode, 'sac', agent, shieldOpts, seed);
end
