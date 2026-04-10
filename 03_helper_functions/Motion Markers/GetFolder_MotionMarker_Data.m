function [All_Geometry, All_Rotation, All_Translation, All_Uncertainty, Number_Timestamps] = GetFolder_MotionMarker_Data(InputDIR, MarkerNames, AverageTracker)
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
    Number_Timestamps = size(InputData_directory, 1);
    Number_Markers = max(size(MarkerNames));
    
    % Preallocate output arrays
    All_Rotation = zeros(3, 3, Number_Timestamps, Number_Markers);
    All_Translation = zeros(3, Number_Timestamps, Number_Markers);
    All_Uncertainty = zeros(3, Number_Timestamps, Number_Markers);
    All_Geometry = zeros(1, Number_Markers);


    % Loop through each marker and each timestamp to extract marker data
    for MarkerID = 1:Number_Markers
        Geometry = 0;
        for timestamp = 1:Number_Timestamps
            filename = fullfile(InputDIR, InputData_directory(timestamp).name);
            [Rotation, Translation, Uncertainty, Geometry] = Get_MotionMarker_Data(filename, MarkerID, AverageTracker);

            % Store results in the output arrays
            All_Rotation(:, :, timestamp, MarkerID) = Rotation;
            All_Translation(:, timestamp, MarkerID) = Translation;
            All_Uncertainty(:, timestamp, MarkerID) = Uncertainty;
        end
        All_Geometry(MarkerID) = Geometry;
    end
end

function [RotMat, TransVec, Uncertainty, Geometry] = Get_MotionMarker_Data(FilePath, MarkerID, AverageTracker)  
    if ~AverageTracker
        [RotMat, TransVec, Uncertainty, Geometry] = Get_MotionMarker_Data_SingleFrame(FilePath, MarkerID, 1);
    elseif AverageTracker
        [RotMat, TransVec, Uncertainty, Geometry] = Get_MotionMarker_Data_Average(FilePath, MarkerID);
    else
        error('AverageTracker needs to be True or False');
    end
end


function [RotMat, TransVec, Uncertainty, Geometry] = Get_MotionMarker_Data_Average(FilePath, MarkerID)
    data = load(FilePath);
    NumberFrames = size(data.markers,1);

    % Initialize arrays to hold rotation matrices and translation vectors
    RotMats = zeros(3, 3, NumberFrames); % 3x3xN for rotation matrices
    TransVecs = zeros(3, NumberFrames);  % 3xN for translation vectors
    Uncertainties = zeros(1, NumberFrames); % 1xN for uncertainties
    
    for frame = 1:NumberFrames % Loop over frames to get the average of the values
        [RotMats(:,:,frame), TransVecs(:,frame), Uncertainties(frame), Geometry] = ...
            Get_MotionMarker_Data_SingleFrame(FilePath, MarkerID, frame);
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

function [RotMat, TransVec, Uncertainty, Geometry] = Get_MotionMarker_Data_SingleFrame(FilePath, MarkerID, Frame)
    data = load(FilePath);
    markers = data.markers;
    % Access marker
    marker = markers{Frame, MarkerID}; 
    RotMat = marker.rotation;
    TransVec = marker.translationMM;
    Uncertainty = marker.registrationErrorMM;
    Geometry = marker.geometryId;
end

