function [Coord_Tib_PoI, Coord_Tib_Points, Coord_Fib_Points, Coord_TestScrews, Fiducials_CTCoord] = Get_SegmentationData_MeasureAD(InputDIR, SelectedMarkers)
    %% Input: Folder for CT Segmentation results, List of Markers that were selected on the CT 
    %% Output: Tibia Point of Interest, Fibula segmentation (in form of Point List), the Coordinates of Motion Markers and the Coordinates of the Screws
    %% Additionally we gat a plot showing the match of the marker geometries in form of a plot
    
    % Calculate the Tibia PoI
    % FilePath_Tib_Landmarks = strcat(InputDIR,'Tibia_Landmarks.json'); % Needs to be Jason File
    % Coord_Tib_Landmarks = Read_3DSlicer_to_Points(FilePath_Tib_Landmarks); % dimension (3,3)
    % FilePath_TibNotch_Tangent = strcat(InputDIR,'TibularNotch_Tangent.json'); % Needs to be Jason File
    % Coord_TibNotch_Tangent = Read_3DSlicer_to_Points(FilePath_TibNotch_Tangent); % dimension (3,2)
    % Coord_Tib_PoI = Calculate_Tibia_PointOfInterest(Coord_Tib_Landmarks, Coord_TibNotch_Tangent);
    
    %Alternative just load Tib PoI from json file directly
    FilePath_Tib_PoI = strcat(InputDIR,'Tibia_PoI.json'); % Needs to be Jason File
    Coord_Tib_PoI = Read_3DSlicer_to_Points(FilePath_Tib_PoI); % dimension (3,3)

    disp('Coordinates of Tibia PoI:')
    disp(Coord_Tib_PoI')
    
    
    %Update_PoI_json(Coord_Tib_PoI, [InputDIR   filesep 'Tibia_PoI.json'])
    % save Coord_Tib_PoI as a .jsonfile

    % Read in the Tibia Segmentations as set of points (if available)
    FilePath_Tib_Points = strcat(InputDIR,'Segmentation_Tibia.stl'); % Needs to be STL File
    try
        Coord_Tib_Points = Read_3DSlicer_to_Points(FilePath_Tib_Points); % Points of Tibula (3xN array)
    catch
        Coord_Tib_Points = Coord_Tib_PoI;
        disp('No file available for Tibia Segmentation.');
    end

    % Read in the Fibula Segmentations as set of points
    FilePath_Fib_Points = strcat(InputDIR,'Segmentation_Fibula.stl'); % Needs to be STL File
    Coord_Fib_Points = Read_3DSlicer_to_Points(FilePath_Fib_Points); % Points of Fibula (3xN array)
    
    % Read the Screws (for quality assurance)
    FilePath_TestScrews = strcat(InputDIR,'TesterScrews.json'); % Needs to be Jason File
    try
        Coord_TestScrews = Read_3DSlicer_to_Points(FilePath_TestScrews); % Points of test screws for diatnce measurement
    catch
        Coord_TestScrews = zeros(3,2);
        disp('No file available for screwmarkers, returning zeros.');
    end
    
    % Read the Fiducials for the selected markers
    [Fiducials_CTCoord] = Get_CTMarkerGeometry(InputDIR, SelectedMarkers);
end

function [Fiducials_CTCoord] = Get_CTMarkerGeometry(MarkerDIR, MarkerList)
    NumberMarkers = size(MarkerList,2);
    Fiducials_CTCoord = zeros(3,4,NumberMarkers); %for fiducials per marker
    for i = 1:NumberMarkers
        Marker = MarkerList(i);
        FilePath_CTCoord_Markers = strcat(MarkerDIR,'MotionMarker_',string(Marker),'.json'); % Needs to be .json File
        Geometry_Marker = Read_3DSlicer_to_Points(FilePath_CTCoord_Markers); % Coordinates of 4 points on a Marker [F0, F1, F2, F3]
        Fiducials_CTCoord(:,:,i) = Geometry_Marker;
    end
end


function [PoI] = Calculate_Tibia_PointOfInterest(L, T)  
    L1 = L(1:2,1)';
    L2 = L(1:2,2)';
    L3 = L(1:2,3)';

    T1 = T(1:2,1)';
    T2 = T(1:2,2)';
        
    % Set up the system of equations for the circle: 
    % (x - xc)^2 + (y - yc)^2 = r^2 
    % Extract coordinates 
    A = [L1; L2; L3]; x = A(:,1); y = A(:,2);
    % Matrix system to solve for xc, yc, and r 
    A_mat = [2*(x(2)-x(1)), 2*(y(2)-y(1)); 2*(x(3)-x(1)), 2*(y(3)-y(1))];
    b = [(x(2)^2 + y(2)^2 - x(1)^2 - y(1)^2); (x(3)^2 + y(3)^2 - x(1)^2 - y(1)^2)];
    % Solve for center (xc, yc) 
    center = A_mat \ b; xc = center(1); yc = center(2); 
    % Calculate the radius 
    r = sqrt((x(1) - xc)^2 + (y(1) - yc)^2); 
    %% Step 2: Parametrize the line through T1 and T2 
    % Parametric line equation: 
    % x = x1 + t*(x2 - x1) % y = y1 + t*(y2 - y1) 
    x1 = T1(1); y1 = T1(2); 
    x2 = T2(1); y2 = T2(2); 
    % dx and dy are direction vectors of the line 
    dx = x2 - x1; dy = y2 - y1; 

    %% Step 3: Find the intersection between the line and the circle 
    % Substitute parametric line into circle equation: 
    % (x - xc)^2 + (y - yc)^2 = r^2 % (x1 + t*dx - xc)^2 + (y1 + t*dy - yc)^2 = r^2 
    % This becomes a quadratic equation in t: At^2 + Bt + C = 0 
    A_quad = dx^2 + dy^2; 
    B_quad = 2*(dx*(x1 - xc) + dy*(y1 - yc)); 
    C_quad = (x1 - xc)^2 + (y1 - yc)^2 - r^2; 
    % Solve the quadratic equation for t 
    discriminant = B_quad^2 - 4*A_quad*C_quad; 
    if discriminant < 0 % No intersection 
        intersectionPoints = []; 
        disp('No intersection between the line and the circle.'); 
        return; 
    end % Compute the two possible solutions for t 
    t1 = (-B_quad + sqrt(discriminant)) / (2*A_quad); 
    t2 = (-B_quad - sqrt(discriminant)) / (2*A_quad); 
    % Compute the intersection points 
    intersection1 = [x1 + t1*dx, y1 + t1*dy]; 
    intersection2 = [x1 + t2*dx, y1 + t2*dy];
    %find Intersaction point further away from L1
    if  sum((L1 - intersection1).^2) > sum((L1 - intersection2).^2)
        PoI = intersection1';
    else
        PoI = intersection2';
    end
    PoI(3,1) = L(3,3); %add z coordinate
end



function [] = Update_PoI_json(PoI, FileName_json)
    jsonText = fileread(FileName_json);              % Read the contents of the .json file as text
    jsonData = jsondecode(jsonText);                 % Decode the JSON text into a MATLAB struct
    
    % Update json points
    jsonData.markups.controlPoints(1).position = PoI;
    
    % Encode the updated struct back into JSON format
    updated_jsonText = jsonencode(jsonData);
    
    % Save the updated JSON text back to the file
    fid = fopen(FileName_json, 'w');                 % Open the file for writing
    if fid == -1
        error('Failed to open the file for writing: %s', FileName_json);
    end
    fwrite(fid, updated_jsonText, 'char');           % Write the updated JSON text
    fclose(fid);                                      % Close the file
end
