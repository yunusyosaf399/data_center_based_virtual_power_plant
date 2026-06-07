function a = rl_get_action_numeric(agent, obs)
%RL_GET_ACTION_NUMERIC Robust extraction of scalar continuous action from RL agent.

try
    act = getAction(agent, {obs});
catch
    try
        act = getAction(agent, obs);
    catch
        act = 0;
    end
end

if iscell(act)
    act = act{1};
end
if isa(act, 'dlarray')
    act = extractdata(act);
end
if isstruct(act)
    fn = fieldnames(act);
    act = act.(fn{1});
end
try
    a = double(act(1));
catch
    a = 0;
end
a = max(-1, min(1, a));
end
