function setup_paths()
%SETUP_PATHS Add the repository MATLAB folders to the path.

    repoRoot = fileparts(mfilename('fullpath'));
    addpath(fullfile(repoRoot, '02_motion_tracking_analysis'));
    addpath(genpath(fullfile(repoRoot, '03_helper_functions')));
    addpath(fullfile(repoRoot, '04_visualisation'));
end
