function sacAgent = create_safe_sac_agent_v842(env, par)
%CREATE_SAFE_SAC_AGENT_V842 Builds SAC agent for the v8.4.2 environment.

obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
numObs = prod(obsInfo.Dimension);
numAct = prod(actInfo.Dimension);

% Actor network: shared torso, mean head, standard deviation head.
commonPath = [
    featureInputLayer(numObs, 'Normalization', 'none', 'Name', 'obs')
    fullyConnectedLayer(256, 'Name', 'actor_fc1')
    reluLayer('Name', 'actor_relu1')
    fullyConnectedLayer(256, 'Name', 'actor_fc2')
    reluLayer('Name', 'actor_relu2')];
meanPath = [
    fullyConnectedLayer(128, 'Name', 'actor_mean_fc')
    reluLayer('Name', 'actor_mean_relu')
    fullyConnectedLayer(numAct, 'Name', 'mean')
    tanhLayer('Name', 'mean_tanh')];
stdPath = [
    fullyConnectedLayer(128, 'Name', 'actor_std_fc')
    reluLayer('Name', 'actor_std_relu')
    fullyConnectedLayer(numAct, 'Name', 'std_fc')
    softplusLayer('Name', 'std')];

actorLG = layerGraph(commonPath);
actorLG = addLayers(actorLG, meanPath);
actorLG = addLayers(actorLG, stdPath);
actorLG = connectLayers(actorLG, 'actor_relu2', 'actor_mean_fc');
actorLG = connectLayers(actorLG, 'actor_relu2', 'actor_std_fc');

try
    actor = rlContinuousGaussianActor(actorLG, obsInfo, actInfo, ...
        'ObservationInputNames', 'obs', ...
        'ActionMeanOutputNames', 'mean_tanh', ...
        'ActionStandardDeviationOutputNames', 'std');
catch
    actor = rlStochasticActorRepresentation(actorLG, obsInfo, actInfo, ...
        'Observation', {'obs'}, ...
        'Action', {'mean_tanh'}, ...
        'Options', rlRepresentationOptions('LearnRate', par.train.actorLearnRate));
end

critic1 = localCreateCritic(obsInfo, actInfo, numObs, numAct, 'critic1');
critic2 = localCreateCritic(obsInfo, actInfo, numObs, numAct, 'critic2');

agentOptions = rlSACAgentOptions;
agentOptions.SampleTime = par.train.sampleTime;
agentOptions.DiscountFactor = par.train.discountFactor;
agentOptions.ExperienceBufferLength = par.train.experienceBufferLength;
agentOptions.MiniBatchSize = par.train.miniBatchSize;
try
    agentOptions.TargetSmoothFactor = 5e-3;
catch
end
try
    agentOptions.ActorOptimizerOptions.LearnRate = par.train.actorLearnRate;
    agentOptions.ActorOptimizerOptions.GradientThreshold = 1;
    agentOptions.CriticOptimizerOptions(1).LearnRate = par.train.criticLearnRate;
    agentOptions.CriticOptimizerOptions(2).LearnRate = par.train.criticLearnRate;
    agentOptions.CriticOptimizerOptions(1).GradientThreshold = 1;
    agentOptions.CriticOptimizerOptions(2).GradientThreshold = 1;
catch
end
try
    agentOptions.EntropyWeightOptions.TargetEntropy = -numAct;
    agentOptions.EntropyWeightOptions.EntropyWeight = par.train.entropyWeight;
catch
end

sacAgent = rlSACAgent(actor, [critic1 critic2], agentOptions);
end

function critic = localCreateCritic(obsInfo, actInfo, numObs, numAct, tag)
obsPath = [
    featureInputLayer(numObs, 'Normalization', 'none', 'Name', [tag '_obs'])
    fullyConnectedLayer(256, 'Name', [tag '_obs_fc1'])
    reluLayer('Name', [tag '_obs_relu1'])
    fullyConnectedLayer(128, 'Name', [tag '_obs_fc2'])];
actPath = [
    featureInputLayer(numAct, 'Normalization', 'none', 'Name', [tag '_act'])
    fullyConnectedLayer(128, 'Name', [tag '_act_fc1'])];
commonPath = [
    additionLayer(2, 'Name', [tag '_add'])
    reluLayer('Name', [tag '_relu2'])
    fullyConnectedLayer(256, 'Name', [tag '_fc3'])
    reluLayer('Name', [tag '_relu3'])
    fullyConnectedLayer(1, 'Name', [tag '_q'])];

lg = layerGraph(obsPath);
lg = addLayers(lg, actPath);
lg = addLayers(lg, commonPath);
lg = connectLayers(lg, [tag '_obs_fc2'], [tag '_add/in1']);
lg = connectLayers(lg, [tag '_act_fc1'], [tag '_add/in2']);

try
    critic = rlQValueFunction(lg, obsInfo, actInfo, ...
        'ObservationInputNames', [tag '_obs'], ...
        'ActionInputNames', [tag '_act']);
catch
    critic = rlQValueRepresentation(lg, obsInfo, actInfo, ...
        'Observation', {[tag '_obs']}, ...
        'Action', {[tag '_act']});
end
end
