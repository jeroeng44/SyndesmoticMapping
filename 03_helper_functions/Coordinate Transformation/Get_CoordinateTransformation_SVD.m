function [R, t] = Get_CoordinateTransformation_SVD(Points_A, Points_B)
    %% INPUT:
    % Points_A: A 3xN matrix where each column represents a 3D point in system A.
    % Points_B: A 3xN matrix where each column represents a 3D point in system B.
    %% OUTPUT:
    % R: The rotation matrix to transform points from system A to system B.
    % t: The translation vector to transform points from system A to system B.
    %% DESCRIPTION:
    % This function calculates the rotation matrix R and translation vector t 
    % that transforms points from coordinate system A to coordinate system B.
    % The relationship is given by the equation: R * A + t = B.
    
    % Check input dimensions
    if size(Points_A, 1) ~= 3 || size(Points_B, 1) ~= 3
        error('Both Points_A and Points_B must have dimensions (3, N).');
    end
    
    if size(Points_A, 2) < 3 || size(Points_B, 2) < 3
        error('Both Points_A and Points_B must contain at least 3 points.');
    end
    
    % Calculate centroids
    centroid_A = mean(Points_A, 2); % 3x1 vector, mean along columns
    centroid_B = mean(Points_B, 2); % 3x1 vector, mean along columns
    
    % Center the points
    centered_A = Points_A - centroid_A; % 3xN matrix
    centered_B = Points_B - centroid_B; % 3xN matrix
    
    % Compute covariance matrix
    covariance_matrix = centered_A * centered_B'; % 3x3
    % Perform Singular Value Decomposition (SVD)
    [U, ~, V] = svd(covariance_matrix);
    
    % Compute the rotation matrix R
    R = V * U';
    
    % Handle reflection case
    if det(R) < 0
        V(:, 3) = -V(:, 3); % Reflect last column of V
        R = V * U';
    end
    
    % Compute the translation vector
    t = centroid_B - R * centroid_A;
end