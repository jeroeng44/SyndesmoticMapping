function [NearestDist, FibPoint, index] = Calculate_NearestNeighbor(PoI, Points, Type)
    %% INPUT:
    %   PoI - Point of interest (3x1 vector).
    %   Points - Set of points (3xN matrix).
    %   Type - Type of distance calculation; can be 'fixed z' or 'all'.
    %% OUTPUT:
    %   NearestDist - Distance to the nearest point.
    %   FibPoint - Coordinates of the nearest point.
    %% DESCRIPTION:
    %   This function determines the nearest distance from a specified point of interest
    %   to a collection of points, based on the specified calculation type.

    if strcmp(Type, 'all')
        RelevantPoints = Points;
    elseif strcmp(Type, 'fixed z')
        z_Slice = PoI(3, 1);
        z_Margin = 0.7; % Consider defining this as a constant at the top of the function
        z_Indices = Points(3, :) > (z_Slice - z_Margin) & Points(3, :) < (z_Slice + z_Margin);
        RelevantPoints = Points(:, z_Indices);
    else
        error('Incorrect AD type specified');
    end
    
    PointCloud = pointCloud(RelevantPoints');
    [index, NearestDist] = findNearestNeighbors(PointCloud, PoI', 1);
    FibPoint = PointCloud.Location(index, :)';
    
    
    if size(index,1) == 0
        % disp('no nearest neighbor found')
        NearestDist = -1;
        FibPoint = PoI;
        index = -1;
    end
end