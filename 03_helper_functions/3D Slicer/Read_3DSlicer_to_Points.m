function [Points] = Read_3DSlicer_to_Points(FileName)
%% INPUT:
%  FileName: (string) Full path to the file from which 3D Slicer data is to be read. 
%            The function is currently compatible with `.json` and `.stl` file formats.
%% OUTPUT:
%  Points: (3xN matrix) Matrix containing 3D point coordinates extracted from the file.
%          The matrix is of size (3, N), where each column corresponds to a point's
%          coordinates (x, y, z), with Points(:,1) representing the coordinates of the first point.
%% DESCRIPTION:
%  This function reads data from a file exported from 3D Slicer, supporting `.json` and `.stl` file formats.
%  Based on the file type, the function calls the appropriate reader function to extract the points.
%  It ensures the output is in the form (3, N), with each column representing the (x, y, z) coordinates of a point.

    % Extract the file extension from the FileName
    [~, ~, ext] = fileparts(FileName);  % Extracts the extension (e.g., '.json')

    % Switch case to handle different file types
    switch lower(ext)  % Convert extension to lowercase to avoid case-sensitivity issues
        case '.json'
            Points = Read_json_to_Points(FileName);  % Read points from a .json file

        case '.stl'
            Points = Read_STL_to_Points(FileName);   % Read points from a .stl file

        otherwise
            disp(['Unknown file type: ' FileName]);  % Display error if file format is not supported
            error('Unsupported file format');        % Terminate function execution
    end

    % Validate that the output points matrix is of size (3, N)
    if size(Points, 1) ~= 3
        disp('Points need to be in the form (3, N)');
        error('Invalid dimensions for Points');
    end
end

%% Reader Function for .json Files
function [Points_json] = Read_json_to_Points(FileName_json)
%% INPUT:
%  FileName_json: (string) Full path to the `.json` file to be read.
%% OUTPUT:
%  Points_json: (3xN matrix) Matrix containing point coordinates extracted from the `.json` file.
%               Each column corresponds to a point's (x, y, z) coordinates.
%% DESCRIPTION:
%  This function reads point data from a `.json` file. The data is structured based on
%  3D Slicer's export format, specifically looking for control points within the markups.
%  The extracted point data is returned as a (3, N) matrix.

    jsonText = fileread(FileName_json);              % Read the contents of the .json file as text
    jsonData = jsondecode(jsonText);                 % Decode the JSON text into a MATLAB struct
    NumberPoints = size(jsonData.markups.controlPoints, 1);  % Get the number of points
    
    % Initialize the points matrix
    Points_json = zeros(3, NumberPoints);
    
    % Loop through each point and extract the coordinates
    for i = 1:NumberPoints
        Points_json(:, i) = jsonData.markups.controlPoints(i).position;  % Assign the point coordinates to the matrix
    end
end

%% Reader Function for .stl Files
function [Points_STL] = Read_STL_to_Points(FileName_STL)
%% INPUT:
%  FileName_STL: (string) Full path to the `.stl` file to be read.
%% OUTPUT:
%  Points_STL: (3xN matrix) Matrix containing point coordinates extracted from the `.stl` file.
%              Each column corresponds to a point's (x, y, z) coordinates.
%% DESCRIPTION:
%  This function reads point data from an `.stl` file using MATLAB's built-in `stlread` function.
%  The data is returned as a (3, N) matrix, where each column corresponds to a point's coordinates.
%  STL files typically contain mesh data, and the unique points are extracted from the mesh structure.

    TR = stlread(FileName_STL);  % Read the .stl file using MATLAB's stlread function
    Points_STL = (TR.Points)';   % Extract and transpose the points to match the (3, N) format
end