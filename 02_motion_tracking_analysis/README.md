# Motion Tracking Analysis

This folder contains the main MATLAB pipeline for computing anterior tibiofibular distance from motion-marker recordings and CT segmentations.

## Entry points

- `Run_Main_Experiment01_MeasureAD_vs_Torque.m`
  Runs the full analysis for one configured experiment.
- `Run_All_Experiments_Summary.m`
  Runs the analysis for all configured experiments and writes a combined CSV summary.
- `Prepare_Experiment01_Specifics_MeasureAD.m`
  Reads per-experiment settings from `config/experiment_registry.csv`.

## Configuration

Before running the code, replace the placeholder paths in `config/experiment_registry.csv` with your local data paths.
