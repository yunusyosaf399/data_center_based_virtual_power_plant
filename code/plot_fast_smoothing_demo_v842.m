function plot_fast_smoothing_demo_v842(par)
%PLOT_FAST_SMOOTHING_DEMO_V842 Illustrative rack/DC smoothing demo.
if nargin < 1 || isempty(par), par = vpp_default_parameters_v842(); end
rng(842);
fs = 10;
t = (0:1/fs:240)';
duty = mod(t,22) < 15.8;
base = 0.72 + 0.12*(2*double(duty)-1);
osc = 0.035*sin(2*pi*2.1*t) + 0.025*sin(2*pi*3.3*t);
noise = 0.01*randn(size(t));
raw = max(0.28, min(1.0, base + osc + noise));
win = round(16*fs);
target = movmean(raw, win);
stabilized = target + 0.004*randn(size(t));
soc = 0.52 + cumsum(raw-stabilized)/numel(t)*0.12;

fig = figure('Name','v8.4.2 AI training smoothing', 'Position',[80 80 1400 760]);
subplot(2,1,1);
plot(t, raw, 'LineWidth', 0.9); hold on; grid on; box on;
plot(t, target, 'k--', 'LineWidth', 1.8);
plot(t, stabilized, 'LineWidth', 1.8);
ylabel('Normalized rack power');
title('AI training load stabilization using rack/DC energy storage');
legend('Original AI training power','Moving-average grid target','Grid-facing stabilized power','Location','best');
subplot(2,1,2);
plot(t, soc, 'LineWidth', 1.8); grid on; box on;
ylabel('Storage charge [-]'); xlabel('Time [s]');
title('Storage charge trajectory during fast power smoothing');
save_figure_v842(fig, 'fig08_ai_training_power_stabilization_timeseries', par);

% Frequency-domain plot
n = numel(t);
f = (0:n-1)'*fs/n;
RawF = abs(fft(raw-mean(raw))).^2/n;
StabF = abs(fft(stabilized-mean(stabilized))).^2/n;
mask = f <= 5 & f > 0;
fig2 = figure('Name','v8.4.2 frequency smoothing', 'Position',[80 80 1400 720]);
semilogy(f(mask), RawF(mask)+1e-30, 'LineWidth', 1.5); hold on; grid on; box on;
semilogy(f(mask), StabF(mask)+1e-30, 'LineWidth', 1.5);
xline(0.2, '--'); xline(3.0, '--');
text(0.23, max(RawF(mask))*0.3, '0.2 Hz', 'Rotation',90, 'FontSize',14);
text(3.03, max(RawF(mask))*0.3, '3 Hz', 'Rotation',90, 'FontSize',14);
ylabel('Power spectral density [a.u.]'); xlabel('Frequency [Hz]');
title('Frequency-domain impact of storage smoothing on AI training power oscillations');
legend('Original AI load','After storage smoothing','Location','best');
save_figure_v842(fig2, 'fig09_frequency_domain_power_smoothing', par);
end
