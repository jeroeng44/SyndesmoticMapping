function [All_Residual_Rotation, All_Residual_Euler, All_Residual_Translation, Residual_RotCenter] = Calculate_Residual_Motion(All_Rotation, All_Translation, Start_Timestamp)
%% INPUT:
%  All_Rotation: (3x3xN matrix) Contains rotation matrices for each timestamp, where N is the number of timestamps.
%  All_Translation: (3xN matrix) Contains translation vectors for each timestamp.
%  MotionDirection: (string) Indicates the direction of motion ('forward' or 'backwards'), defining the reference frame for calculating residuals.
%% OUTPUT:
%  All_Residual_Rotation: (3x3xN matrix) Contains the residual rotation matrices for each timestamp.
%  All_Residual_Euler: (3xN matrix) Contains the residual Euler angles (in degrees) for each timestamp.
%  All_Residual_Translation: (3xN matrix) Contains the residual translation vectors for each timestamp.
%  Residual_RotCenter: (3x1 vector) Represents the rotation center at the starting timestamp.
%% DESCRIPTION:
%  This function calculates the residual motion (rotation and translation) based on provided rotation and translation matrices.
%  The calculation is performed in either the forward or backward direction, depending on the specified motion direction.
%  It computes the difference in rotation and translation relative to a reference timestamp.

    Number_Timestamps = size(All_Rotation, 3);  % Get the number of timestamps
    
    % Initialize arrays for storing residual results
    All_Residual_Rotation = zeros(3, 3, Number_Timestamps);  % Residual rotation matrices
    All_Residual_Euler = zeros(3, Number_Timestamps);          % Residual Euler angles
    All_Residual_Translation = zeros(3, Number_Timestamps);    % Residual translation vectors
    
    % Calculate residuals for each timestamp
    for timestamp = 1:Number_Timestamps
        All_Residual_Rotation(:,:,timestamp) = All_Rotation(:,:,timestamp) * (All_Rotation(:,:,Start_Timestamp))';  % Compute residual rotation
        All_Residual_Euler(:,timestamp) = rotm2eul(All_Residual_Rotation(:,:,timestamp)) * 180/pi;  % Convert rotation matrix to Euler angles (degrees)
        All_Residual_Translation(:,timestamp) = All_Translation(:,timestamp) - All_Translation(:,Start_Timestamp);  % Compute residual translation
    end
    Residual_RotCenter = All_Translation(:,Start_Timestamp);  % Get the rotation center based on the start timestamp
end