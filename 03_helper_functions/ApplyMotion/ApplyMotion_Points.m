function [Moved_Points] = ApplyMotion_Points(Points, T, R, C, direction)
%% INPUT:
%  Points: (3xN matrix) The coordinates of N points in 3D space.
%  TransVec: (3x1 vector) The translation vector to apply to the points.
%  RotMat: (3x3 matrix) The rotation matrix to apply to the points.
%  RotCenter: (3x1 vector) The center point around which rotation is applied.
%% OUTPUT:
%  Moved_Points: (3xN matrix) The coordinates of the points after applying translation and rotation.
%% DESCRIPTION:
%  This function applies a translation and rotation to a set of 3D points.
%  The rotation is performed around a specified rotation center, and all transformations are applied in the same coordinate system.

%% Function
    % Validate input dimensions for Points
    if size(Points, 1) ~= 3
        disp('Points requires the dimensions (3,N)');  % Informative error message
        error('Invalid dimensions for Points. Expected (3,N).');  % Error termination with descriptive message
    end
    
    NumberPoints = size(Points, 2);  % Get the number of points
    Moved_Points = Points;  % Initialize Moved_Points with the original Points
    
    % Apply motion to each point
    for i = 1:NumberPoints
        if strcmp(direction,'normal')
                Moved_Points(:, i) = R * (Points(:, i) - C) + C +T;
        elseif strcmp(direction,'inv')
                Moved_Points(:, i) = R' * (Points(:, i) - T -C) + C;
        else
            error('direction needs to be normal or inv');
        end
    
    end
end
