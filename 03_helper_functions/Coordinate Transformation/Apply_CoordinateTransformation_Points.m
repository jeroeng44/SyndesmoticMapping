function [Points_new] = Apply_CoordinateTransformation_Points(Points, R, T, direction)
% points in the form 3xN
% direction can be 'inv' or 'normal'
    N = size(Points,2);
    Points_new = Points * 0;
    for i = 1:N
        if strcmp(direction,'normal')
            Points_new(:,i) = R * Points(:,i) + T;
        elseif strcmp(direction,'inv')
            Points_new(:,i) = R' * (Points(:,i) - T);
        else
            error('direction needs to be normal or inv');
        end
    end
end