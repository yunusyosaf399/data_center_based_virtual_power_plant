function plot_publication_architecture_v842(par)
%PLOT_PUBLICATION_ARCHITECTURE_V842 Architecture diagram.
if nargin < 1 || isempty(par), par = vpp_default_parameters_v842(); end
fig = figure('Name','v8.4.2 architecture', 'Position',[80 80 1450 820]);
axis off; hold on;
title('Safe-SAC VPP-enabled green data-center battery dispatch architecture', 'FontSize', 22, 'FontWeight','bold');

boxStyle = {'Curvature',0.04,'LineWidth',1.8,'EdgeColor','k','FaceColor',[0.96 0.96 0.96]};
annotation('rectangle',[0.03 0.72 0.18 0.11],boxStyle{:});
annotation('textbox',[0.035 0.735 0.17 0.08],'String','AI data-center load\ntraining cycles','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.03 0.55 0.18 0.11],boxStyle{:});
annotation('textbox',[0.035 0.565 0.17 0.08],'String','On-site PV +\nforecast uncertainty','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.03 0.38 0.18 0.11],boxStyle{:});
annotation('textbox',[0.035 0.395 0.17 0.08],'String','VPP coordinator\nP_{grid,ref} + DR event','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.03 0.17 0.18 0.11],boxStyle{:});
annotation('textbox',[0.035 0.185 0.17 0.08],'String','Tariff + stress\nscenarios','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');

annotation('rectangle',[0.31 0.54 0.22 0.17],boxStyle{:});
annotation('textbox',[0.315 0.57 0.21 0.10],'String','22-state observation\nSOC, forecasts, prices,\nflexibility, DR lookahead','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.62 0.61 0.17 0.11],boxStyle{:});
annotation('textbox',[0.625 0.628 0.16 0.07],'String','SAC actor\n\pi_\theta(a|o)','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.62 0.44 0.17 0.15],boxStyle{:});
annotation('textbox',[0.625 0.462 0.16 0.09],'String','Safety layer\nSOC + ramp + power\nDR cap + terminal SOC','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.86 0.52 0.13 0.16],boxStyle{:});
annotation('textbox',[0.865 0.56 0.12 0.08],'String','Battery + grid\nphysical plant','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.83 0.25 0.17 0.14],boxStyle{:});
annotation('textbox',[0.835 0.275 0.16 0.08],'String','Reward + metrics\ncost, RMSE, DR,\nSOC, degradation','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');
annotation('rectangle',[0.35 0.23 0.20 0.12],boxStyle{:});
annotation('textbox',[0.355 0.25 0.19 0.07],'String','Publication tests\nbaselines + ablation\nstress scenarios','FontSize',14,'HorizontalAlignment','center','EdgeColor','none');

arrow = {'LineWidth',1.8,'HeadLength',10,'HeadWidth',10};
annotation('arrow',[0.21 0.31],[0.78 0.63],arrow{:});
annotation('arrow',[0.21 0.31],[0.61 0.63],arrow{:});
annotation('arrow',[0.21 0.31],[0.44 0.63],arrow{:});
annotation('arrow',[0.12 0.31],[0.28 0.63],arrow{:});
annotation('arrow',[0.53 0.62],[0.625 0.66],arrow{:});
annotation('arrow',[0.705 0.705],[0.61 0.59],arrow{:});
annotation('arrow',[0.79 0.86],[0.51 0.60],arrow{:});
annotation('arrow',[0.93 0.93],[0.52 0.39],arrow{:});
annotation('arrow',[0.83 0.55],[0.32 0.29],arrow{:});
annotation('arrow',[0.62 0.53],[0.52 0.61],arrow{:});
annotation('textbox',[0.03 0.04 0.90 0.05], 'String', ...
    'v8.4.2 contribution: learned SAC dispatch is wrapped by a physics/VPP shield, then benchmarked against no-battery, greedy, rule-based, and TOU baselines under deterministic and stress scenarios.', ...
    'FontSize', 13, 'EdgeColor','none');
save_figure_v842(fig, 'fig11_safe_sac_vpp_architecture', par);
end
