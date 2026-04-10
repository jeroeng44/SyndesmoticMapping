function [Moved_Points] = ApplyMotion_Points(Points, TransVec, RotMat, RotCenter)
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

    % Validate input dimensions for Points
    if size(Points, 1) ~= 3
        disp('Points requires the dimensions (3,N)');  % Informative error message
        error('Invalid dimensions for Points. Expected (3,N).');  % Error termination with descriptive message
    end
    
    NumberPoints = size(Points, 2);  % Get the number of points
    Moved_Points = Points;  % Initialize Moved_Points with the original Points
    
    % Apply motion to each point
    for i = 1:NumberPoints
        Moved_Points(:, i) = ApplyMotion_SinglePoint(Points(:, i), TransVec, RotMat, RotCenter);  % Update each point
    end
end

function [Moved_Point] = ApplyMotion_SinglePoint(Point, TransVec, RotMat, RotCenter)
%% INPUT:
%  Point: (3x1 vector) The coordinates of a single point in 3D space.
%  TransVec: (3x1 vector) The translation vector to apply to the point.
%  RotMat: (3x3 matrix) The rotation matrix to apply to the point.
%  RotCenter: (3x1 vector) The center point around which rotation is applied.
%% OUTPUT:
%  Moved_Point: (3x1 vector) The coordinates of the point after applying translation and rotation.
%% DESCRIPTION:
%  This function applies translation and rotation to a single 3D point.
%  The rotation is performed around a specified rotation center.

    % Convert inputs to ensure they are vectors
    Moved_Point = Point;  % Initialize Moved_Point with the original Point
    Moved_Point = ConvertVector(Moved_Point);  % Ensure Point is a column vector
    TransVec = ConvertVector(TransVec);  % Ensure TransVec is a column vector
    RotCenter = ConvertVector(RotCenter);  % Ensure RotCenter is a column vector
    
    % Apply rotation around the rotation center and then translation
    Moved_Point = Apply_Rotation(Moved_Point, RotMat, RotCenter);
    Moved_Point = ApplyTranslation(Moved_Point, TransVec);
end

%% Helper Function: Rotation
function [Rotated_Point] = Apply_Rotation(Point, RotMat, RotCenter)
%% INPUT:
%  Point: (3x1 vector) The coordinates of the point to be rotated.
%  RotMat: (3x3 matrix) The rotation matrix to apply to the point.
%  RotCenter: (3x1 vector) The center point around which rotation is applied.
%% OUTPUT:
%  Rotated_Point: (3x1 vector) The coordinates of the point after rotation.
%% DESCRIPTION:
%  This function applies rotation to a point around a specified rotation center.

    Rotated_Point = Point;  % Initialize Rotated_Point with the original Point
    Rotated_Point = ApplyTranslation(Rotated_Point, -1 * RotCenter);  % Move point to origin for rotation
    Rotated_Point = ApplySimpleRotation(Rotated_Point, RotMat);  % Apply the rotation
    Rotated_Point = ApplyTranslation(Rotated_Point, RotCenter);  % Move point back to original position
end

%% Helper Function: Simple Rotation (around Coordinate Origin)
function [Rotated_Point] = ApplySimpleRotation(Point, RotMat)
%% INPUT:
%  Point: (3x1 vector) The coordinates of the point to be rotated.
%  RotMat: (3x3 matrix) The rotation matrix to apply to the point.
%% OUTPUT:
%  Rotated_Point: (3x1 vector) The coordinates of the point after rotation.
%% DESCRIPTION:
%  This function applies a simple rotation to a point using a provided rotation matrix.

    Rotated_Point = Point;  % Initialize Rotated_Point with the original Point
    Rotated_Point = RotMat * Rotated_Point;  % Apply rotation
end

%% Helper Function: Translation
function [Translated_Point] = ApplyTranslation(Point, TransVec)
%% INPUT:
%  Point: (3x1 vector) The coordinates of the point to be translated.
%  TransVec: (3x1 vector) The translation vector to apply to the point.
%% OUTPUT:
%  Translated_Point: (3x1 vector) The coordinates of the point after translation.
%% DESCRIPTION:
%  This function applies translation to a point using a provided translation vector.

    Translated_Point = Point;  % Initialize Translated_Point with the original Point
    Translated_Point = Translated_Point + TransVec;  % Apply translation
end

%% Helper Function: Ensure it's a real Vector
function [Vector] = ConvertVector(Vector_or_Point)
%% INPUT:
%  Vector_or_Point: (vector or point) The input that may be a point or a vector.
%% OUTPUT:
%  Vector: (3x1 vector) The output as a column vector.
%% DESCRIPTION:
%  This function ensures that the input is a column vector by transposing it if necessary.

    Vector = Vector_or_Point;  % Initialize Vector with the input
    if (size(Vector, 1) == 1) && (size(Vector, 2) > 1)
        Vector = Vector';  % Transpose if it's a row vector
    end
end