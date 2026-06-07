%% clean_old_results_for_v842.m
% Deletes old v8.4.2 trained agents/results and figures so v8.4.2 runs cleanly.

clear; clc;
rootDir = fileparts(mfilename('fullpath'));
[~, lastFolder] = fileparts(rootDir);
if strcmpi(lastFolder, 'code')
    rootDir = fileparts(rootDir);
end
if isempty(rootDir)
    rootDir = pwd;
end
resultsDir = fullfile(rootDir, 'results');
figDir = fullfile(rootDir, 'figures');

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

if exist(resultsDir, 'dir')
    delete(fullfile(resultsDir, '*.mat'));
    delete(fullfile(resultsDir, '*.csv'));
    oldDirs = {'savedAgents_SAC_v842', 'training_v842'};
    for i = 1:numel(oldDirs)
        d = fullfile(resultsDir, oldDirs{i});
        if exist(d, 'dir')
            rmdir(d, 's');
        end
    end
end

if exist(figDir, 'dir')
    delete(fullfile(figDir, '*.png'));
    delete(fullfile(figDir, '*.pdf'));
    delete(fullfile(figDir, '*.fig'));
end

fprintf('Old v8.4.2 results and figures removed. v8.4.2 is ready for a clean run.\n');
