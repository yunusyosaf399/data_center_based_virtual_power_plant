function save_figure_v842(figHandle, baseName, par)
%SAVE_FIGURE_V842 Saves current figure to figures folder.
if nargin < 1 || isempty(figHandle), figHandle = gcf; end
if nargin < 2, baseName = 'figure'; end
if nargin < 3 || isempty(par), par = vpp_default_parameters_v842(); end
rootDir = fileparts(fileparts(mfilename('fullpath')));
figDir = fullfile(rootDir, 'figures');
if ~exist(figDir, 'dir'), mkdir(figDir); end
set(figHandle, 'Color', 'w');
try
    exportgraphics(figHandle, fullfile(figDir, [baseName '.png']), 'Resolution', 220);
catch
    saveas(figHandle, fullfile(figDir, [baseName '.png']));
end
if isfield(par, 'plot') && isfield(par.plot, 'savePDF') && par.plot.savePDF
    try
        exportgraphics(figHandle, fullfile(figDir, [baseName '.pdf']), 'ContentType', 'vector');
    catch
        saveas(figHandle, fullfile(figDir, [baseName '.pdf']));
    end
end
try
    savefig(figHandle, fullfile(figDir, [baseName '.fig']));
catch
end
end
