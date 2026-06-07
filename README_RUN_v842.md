# Safe-SAC VPP Green Data-Center Battery Dispatch — v8.4.2

This package is the v8.4.2 economic-relaxation version. It starts from v8.4.1 and keeps the same publication-test workflow, but changes the controller objective and safety layer to reduce economic over-conservatism.

## What is new in v8.4.2

1. **Tariff-aware VPP tracking**: tracking is still strong during DR/peak-constrained intervals, but slightly relaxed during non-service high/low-price periods.
2. **Soft economic coach**: the safety layer now adds a mild high-price discharge / low-price recharge advisory before hard projection.
3. **Hard clipping separated from soft coaching**: `ActionClippedFraction` now reports hard safety projection only; `SoftCoachActionFraction` reports advisory intervention.
4. **Less conservative terminal SOC shield**: shorter terminal soft window and fewer hard terminal steps.
5. **Reduced peak margin**: peak safety remains hard, but unnecessary margin is lowered to recover economic flexibility.
6. **Curriculum training mode**: training alternates stochastic, low-PV, high-PV, and combined-stress days.
7. **Same publication tests**: deterministic evaluation, ablation, controller baselines, stochastic robustness, and combined-stress comparison.

## Target for v8.4.2

Compared with v8.4.1, the goal is to keep:

- DR success: 100%
- terminal SOC error: below 1%
- VPP tracking RMSE: preferably below 70–80 kW
- peak import: preferably below 1300–1400 kW

while improving:

- daily operating cost versus v8.4.1
- hard action clipping versus v8.4.1

## Quick start

In MATLAB, run:

```matlab
cd('.../safe_sac_vpp_datacenter_v842/code')
run_smoke_test_without_training
```

Then train and evaluate:

```matlab
run_all_v842
```

## Main scripts

- `run_all_v842.m` — full clean run: train, evaluate, compare, plot.
- `run_smoke_test_without_training.m` — checks paths, environment, safety filter, baseline evaluation.
- `run_v842_publication_tests.m` — deterministic evaluation, stochastic tests, baselines, ablation, stress tests.
- `train_safe_sac_v842.m` — trains SAC agent and saves checkpoints.
- `evaluate_agent_vpp.m` — deterministic or scenario evaluation.
- `run_v842_controller_comparison.m` — publication baseline table.
- `run_v842_ablation_after_training.m` — shield ablation table.
- `run_v842_stochastic_robustness.m` — stochastic robustness table and boxplots.
- `run_v842_combined_stress_comparison.m` — combined-stress controller comparison.
- `plot_v842_all_results.m` — publication figures.

## Expected MATLAB toolboxes

- Reinforcement Learning Toolbox
- Deep Learning Toolbox

The smoke test can run baseline controllers without training, but SAC training needs Reinforcement Learning Toolbox.
