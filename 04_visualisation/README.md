# Visualisation

This folder contains MATLAB utilities for inspecting motion-mapped tibia and fibula geometries and for creating GIF animations from exported frame sequences.

## Included tools

- `MotionTrackingDisplay_Syndesmose.mlapp`
  MATLAB App Designer viewer for a folder containing timestep-wise `.mat` files named:
  - `Fib_Seg_0001.mat`
  - `Tib_Seg_0001.mat`
  - `Tib_PoI_0001.mat`
- `GIFCreator.m`
  Utility to convert PNG frames into an animated GIF.

## Expected app input

The app expects each `.mat` file to contain a single `3 x N` point matrix for the corresponding structure at one timestep.
