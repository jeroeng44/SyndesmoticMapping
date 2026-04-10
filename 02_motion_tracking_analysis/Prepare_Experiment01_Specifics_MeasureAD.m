function [Motion_InputDir, Segmentation_InputDIR, OutputDir, MotionMarkers_measured, MotionMarkers_CTvisible, which_leg, Torque_FileName, Torque_Channel, Torque_PlotRange, MotionDirection] = ...
    Prepare_Experiment01_Specifics_MeasureAD(Name)
%PREPARE_EXPERIMENT01_SPECIFICS_MEASUREAD Load neutral experiment config.
%   This function reads experiment metadata from
%   02_motion_tracking_analysis/config/experiment_registry.csv.
%
%   Replace the placeholder values in that CSV with your local data paths
%   before running the analysis.

    registry = read_experiment_registry();
    experimentName = lower(string(Name));
    row = registry(strcmpi(registry.experiment, experimentName), :);

    if height(row) ~= 1
        error('Experiment "%s" was not found in config/experiment_registry.csv.', experimentName);
    end

    validate_registry_row(row);

    Motion_InputDir = ensure_trailing_filesep(row.motion_input_dir{1});
    Segmentation_InputDIR = ensure_trailing_filesep(row.segmentation_input_dir{1});
    OutputDir = ensure_trailing_filesep(row.output_dir{1});
    MotionMarkers_measured = parse_numeric_list(row.motion_markers_measured{1});
    MotionMarkers_CTvisible = parse_numeric_list(row.motion_markers_ctvisible{1});
    which_leg = lower(strtrim(row.which_leg{1}));
    Torque_FileName = row.torque_file_name{1};
    Torque_Channel = row.torque_channel{1};
    Torque_PlotRange = parse_numeric_list(row.torque_plot_range{1});
    MotionDirection = lower(strtrim(row.motion_direction{1}));
end

function registry = read_experiment_registry()
    thisFile = mfilename('fullpath');
    configDir = fullfile(fileparts(thisFile), 'config');
    registryFile = fullfile(configDir, 'experiment_registry.csv');

    if ~isfile(registryFile)
        error('Missing config file: %s', registryFile);
    end

    registry = readtable(registryFile, 'TextType', 'string');
    registry = standardizeMissing(registry, "");
end

function validate_registry_row(row)
    placeholderPrefixes = ["<", "REPLACE_", "PATH/TO", "/path/to"];
    fieldsToCheck = ["motion_input_dir", "segmentation_input_dir", "output_dir", "torque_file_name"];

    for i = 1:numel(fieldsToCheck)
        value = strtrim(string(row.(fieldsToCheck(i))(1)));
        if value == "" || any(startsWith(value, placeholderPrefixes))
            error('Config field "%s" for experiment "%s" still contains a placeholder value.', ...
                fieldsToCheck(i), row.experiment(1));
        end
    end

    if ~ismember(lower(strtrim(string(row.which_leg(1)))), ["left", "right"])
        error('Field "which_leg" must be "left" or "right".');
    end

    if ~ismember(lower(strtrim(string(row.motion_direction(1)))), ["forward", "backwards"])
        error('Field "motion_direction" must be "forward" or "backwards".');
    end

    range = parse_numeric_list(row.torque_plot_range{1});
    if numel(range) ~= 2
        error('Field "torque_plot_range" must contain exactly two integers.');
    end
end

function values = parse_numeric_list(value)
    tokens = regexp(char(string(value)), '\d+', 'match');
    values = str2double(tokens);
end

function pathOut = ensure_trailing_filesep(pathIn)
    pathOut = char(string(pathIn));
    if ~endsWith(pathOut, filesep)
        pathOut = [pathOut filesep];
    end
end
