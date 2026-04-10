function [All_Geometry, All_Rotation, All_Translation, All_Uncertainty, All_Times, Number_Timestamps] = GetFolder_MotionMarker_Data_withTime(InputDIR, MarkerNames, AverageTracker)
    %% INPUT:
    %   InputDIR - Directory containing marker transformation data files.
    %  MarkerNames - Name of the markers in the order they have been measured
    %   AverageTracker - Boolean, true/ false if average over frames
    %% OUTPUT:
    %   All_Rotation - A 3x3xNxM matrix containing rotation matrices for each timestamp (N) and each marker (M).
    %   All_Translation - A 3xNxM matrix containing translation vectors for each timestamp (N) and each marker (M).
    %   All_Uncertainty - A 3xNxM matrix containing uncertainty values for each timestamp (N) and each marker (M).
    %% DESCRIPTION:
    %   This function retrieves the rotation and translation data for all
    %   motion markers specified in the input
    %   from .mat files in the specified input directory

    % Find all .mat files in the input directory
    InputDIR_Files = strcat(InputDIR, '*.mat');
    InputData_directory = dir(InputDIR_Files);

    % Skip AppleDouble / hidden files (macOS sidecars start with ._)
    names = {InputData_directory.name};
    keep = ~startsWith(names, '._') & ~startsWith(names, '.');
    InputData_directory = InputData_directory(keep);

    Number_Timestamps = numel(InputData_directory);
    Number_Markers = max(size(MarkerNames));
    
    % Quality assurance
    if Number_Timestamps == 0 || Number_Markers == 0
        error('No valid data found in the input directory or marker names.');
    end


    % Preallocate output arrays
    All_Rotation = zeros(3, 3, Number_Timestamps, Number_Markers);
    All_Translation = zeros(3, Number_Timestamps, Number_Markers);
    All_Uncertainty = zeros(3, Number_Timestamps, Number_Markers);
    All_Geometry = zeros(1, Number_Markers);
    All_Times = zeros(1, Number_Timestamps);


    % Loop through each marker and each timestamp to extract marker data
    for MarkerID = 1:Number_Markers
        Geometry = 0;
        for timestamp = 1:Number_Timestamps
            filename = fullfile(InputDIR, InputData_directory(timestamp).name);
            [Rotation, Translation, Uncertainty, Geometry, Time] = Get_MotionMarker_Data(filename, MarkerID, AverageTracker);

            % Store results in the output arrays
            All_Rotation(:, :, timestamp, MarkerID) = Rotation;
            All_Translation(:, timestamp, MarkerID) = Translation;
            All_Uncertainty(:, timestamp, MarkerID) = Uncertainty;
            All_Times(1, timestamp) = Time;
        end
        All_Geometry(MarkerID) = Geometry;
    end


    % Replace time with 1:No_Timestamps if it is filled with -999
    eps = 10^-5;
    timenotavailable = all(abs(All_Times - All_Times(1)) < eps); % Returns true if all elements are equal to 5
    if timenotavailable
        All_Times = 1: Number_Timestamps;
    end


    %here we need to implement a sorting mechanism since the geometryID of
    %our markers order varies in our data collected from the motion
    %tracking, the 
    %right order would be 299,302,302,311,314,320   
    %to make the code more robust implement that it make the right order
    %even if the markers were called 100029900 or something like that
    %also implement some debug statements so that i understand whats going
    %on, here is a snippet of code that can be used as guidance
%XXX
% Sort marker data to ensure correct order based on MarkerNames
All_Rotation_sorted = zeros(size(All_Rotation)); % Preallocate sorted rotation matrix
All_Translation_sorted = zeros(size(All_Translation)); % Preallocate sorted translation matrix
All_Uncertainty_sorted = zeros(size(All_Uncertainty)); % Preallocate sorted uncertainty matrix
All_Geometry_sorted = zeros(size(All_Geometry)); % Preallocate sorted geometry array

for i = 1:length(MarkerNames)
    CurrName = MarkerNames(i);
    
    % Find the index in All_Geometry corresponding to CurrName
    k = find(arrayfun(@(x) contains(num2str(All_Geometry(x)), num2str(CurrName)), 1:length(All_Geometry)));
    
    if isempty(k)
        error('Marker name %d not found in geometry data. Check MarkerNames and input data.', CurrName);
    elseif length(k) > 1
        error('Multiple matches found for marker name %d. Ensure unique geometry IDs.', CurrName);
    end
    
    % Debug: Print mapping details before sorting
    fprintf('Debug before sorting takes place: Mapping MarkerName %d to index %d in All_Geometry.\n', CurrName, k);
    
    % Sort data for the current marker
    All_Rotation_sorted(:,:,:,i) = All_Rotation(:,:,:,k);
    All_Translation_sorted(:,:,i) = All_Translation(:,:,k);
    All_Uncertainty_sorted(:,:,i) = All_Uncertainty(:,:,k);
    All_Geometry_sorted(i) = All_Geometry(k);
end

% Update the sorted outputs
All_Rotation = All_Rotation_sorted;
All_Translation = All_Translation_sorted;
All_Uncertainty = All_Uncertainty_sorted;
All_Geometry = All_Geometry_sorted;

% Debug: Confirm sorting completion
fprintf('Debug: Sorting of marker data completed. Output arrays updated.\n');
%XXX
end

function [RotMat, TransVec, Uncertainty, Geometry, Time] = Get_MotionMarker_Data(FilePath, MarkerID, AverageTracker)  
    
    if islogical(AverageTracker)
        if AverageTracker
            [RotMat, TransVec, Uncertainty, Geometry, Time] = Get_MotionMarker_Data_Average(FilePath, MarkerID);
        else
            [RotMat, TransVec, Uncertainty, Geometry, Time] = Get_MotionMarker_Data_SingleFrame(FilePath, MarkerID, 1);
        end
    else
        error('AverageTracker must be a logical true or false.');
    end
end


function [RotMat, TransVec, Uncertainty, Geometry, Time] = Get_MotionMarker_Data_Average(FilePath, MarkerID)
    data = load(FilePath);
    NumberFrames = size(data.markers,1);

    % Initialize arrays to hold rotation matrices and translation vectors
    RotMats = zeros(3, 3, NumberFrames); % 3x3xN for rotation matrices
    TransVecs = zeros(3, NumberFrames);  % 3xN for translation vectors
    Uncertainties = zeros(1, NumberFrames); % 1xN for uncertainties
    
    for frame = 1:NumberFrames % Loop over frames to get the average of the values
        [RotMats(:,:,frame), TransVecs(:,frame), Uncertainties(frame), Geometry] = ...
            Get_MotionMarker_Data_SingleFrame(FilePath, MarkerID, frame, Time);
    end

    % Average the rotation matrices using the Karcher mean or quaternions
    RotMat = AverageRotationMatrices(RotMats); 

    % Average the translation vectors
    TransVec = mean(TransVecs, 2); % Average translation vectors (3x1)

    % Estimate uncertainty, can be adjusted based on your requirements
    Uncertainty = std(Uncertainties); % Example: standard deviation of uncertainties
end

function RotMatAvg = AverageRotationMatrices(RotMats)
    % This function averages a set of rotation matrices using quaternion method
    
    N = size(RotMats, 3); % Number of rotation matrices
    Quats = zeros(N, 4);  % Initialize quaternion array

    for i = 1:N
        % Convert rotation matrix to quaternion
        Quats(i, :) = rotm2quat(RotMats(:,:,i)); % MATLAB function to convert to quaternion
    end

    % Average quaternions
    QuatAvg = mean(Quats, 1); % Simple mean (may not be valid rotation)
    QuatAvg = QuatAvg / norm(QuatAvg); % Normalize the average quaternion

    % Convert back to rotation matrix
    RotMatAvg = quat2rotm(QuatAvg); % MATLAB function to convert back to rotation matrix
end

function [RotMat, TransVec, Uncertainty, Geometry, Time] = Get_MotionMarker_Data_SingleFrame(FilePath, MarkerID, Frame)
    data = load(FilePath);
    markers = data.markers;
    marker = markers{Frame, MarkerID};
    fprintf('DEBUG: File=%s | MarkerID=%s | class=%s | size=%s\n', ...
    char(FilePath), num2str(MarkerID), class(marker), mat2str(size(marker)));
    RotMat = marker.rotation;
    TransVec = marker.translationMM;
    Uncertainty = marker.registrationErrorMM;
    Geometry = marker.geometryId;

    if isfield(data, 'time')
        Time = data.time;
    else
        Time = -999;
    end
end

