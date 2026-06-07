function plot_hierarchical_ess_v842(par)
%PLOT_HIERARCHICAL_ESS_V842 ESS response-time and capacity hierarchy.
if nargin < 1 || isempty(par), par = vpp_default_parameters_v842(); end
labels = {'UPS/GIUPS','Server buffer','Rack BBU','Grid BESS','GPU capacitor','Datacenter BESS'};
respS = [1, 0.01, 0.1, 300, 0.001, 60];
capMWh = [2, 0.01, 0.2, 200, 0.001, 20];
fig = figure('Name','v8.4.2 hierarchical ESS', 'Position',[80 80 1400 720]);
subplot(1,2,1);
barh(categorical(labels), respS); set(gca,'XScale','log'); grid on; box on;
xlabel('Representative response time [s, log scale]');
title('Hierarchical ESS response times for AI data centers');
subplot(1,2,2);
barh(categorical(labels), capMWh); set(gca,'XScale','log'); grid on; box on;
xlabel('Representative energy capacity [MWh, log scale]');
title('Hierarchical ESS energy-capacity scale');
save_figure_v842(fig, 'fig10_hierarchical_ess_timescale_capacity', par);
end
