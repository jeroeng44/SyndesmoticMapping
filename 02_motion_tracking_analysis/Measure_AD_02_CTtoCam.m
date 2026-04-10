function [AntTibDist, ScrewDistance] = Measure_AD_02_CTtoCam(Marker_InputDIR, CT_InputDIR, Segmentation_OutputDIR, MarkersMeasured, MarkerOnCT, Selected_Leg, MotionDirection)
    %% Function Descriptption
    %% INPUT:
    %   Marker_InputDIR - Directory containing marker data.
    %   CT_InputDIR - Directory containing CT data.
    %   MarkerOnCT - Markers visible on CT (to be used for coordinate registration between CT and camera.
    %   Selected_Leg - Selected leg for analysis.
    %   MotionDirection - A string indicating the motion direction; allowed values are 'forward' and 'backward'.
    %% OUTPUT:
    %   AntTibDist - Anterior tibiofibular distance over time.
    %   ScrewDistance - Distance between screws over time.
    %% DESCRIPTION:
    %   Anterior tibiofibular distance is calculated by
    %   -   Registering CT coordinate system to camera coordinate system
    %   -   Moving the relevant points using the residual motion (i.e. motion model 2)
     
    %% Initialization
    % Get marker names and IDs for later use
    [~, CT_Markers_ID] = ismember(MarkerOnCT, MarkersMeasured); %indices of the markers visible on the CT
    [~, Leg_Markers_ID] = ismember(Get_MarkerNames_from_Leg_Measure_AD(Selected_Leg), MarkersMeasured); % indices of the markers corresponding to the leg
    TibiaID = Leg_Markers_ID(1);
    FibulaID = Leg_Markers_ID(2); 

    %% Get CT Segmentation Data
    % Function Get_SegmentationData to get the relevant anatomy data
    % CT to be manually segmented previous to running the analysis scrip
    % Details in  "How-To-Presentation"
    [Tib_PoI_CT, Tib_Points_CT, Fib_Points_CT, Screws_CT, Fiducials_CT] = Get_SegmentationData_MeasureAD(CT_InputDIR, MarkerOnCT);   
    % disp('Tibia PoI')
    % disp(Tib_PoI_CT)
    
    MarkerPos_CT = reshape(Fiducials_CT(:,1,:), [size(Fiducials_CT,1), size(Fiducials_CT,3)]);
    Tib_Screws_CT = Screws_CT(:, 1);
    Fib_Screws_CT = Screws_CT(:, 2);

    %% Get MotionMarker Data:
    % Here we pull all the data available for the motion marker
    % AverageTracker indicates if we average over the 3 frames per timestamp (TRUE) or just take the first frame (FALSE)
    [All_Geometry, AllMarker_Rotation, AllMarker_Translation, ~, Number_Timestamps] = ...
        GetFolder_MotionMarker_Data(Marker_InputDIR, MarkersMeasured, false);
%     QualityAssurance_Geometry(MarkersMeasured, All_Geometry); %returns an error if no match with expected markers
    
    % Determine the CT_Timestamp based on the motion direction
    % If forward CT_Timestamp = 1, if 'backwards' CT_Timestamp = Number_Timestamps;
    CT_Timestamp = Get_CT_Timestamp(MotionDirection, Number_Timestamps);
         
    % Extract coordinates of the markers on the reference timeframe
    MarkerPos_Cam = AllMarker_Translation(:, CT_Timestamp, CT_Markers_ID); % Only select relevant timestamp and markers on CT
    MarkerPos_Cam = reshape(MarkerPos_Cam, [3, max(size(MarkerOnCT))]);  % Reshape into 3 x Number of markers visible on CT for registration
    
    % Extract Motion Data for relevant markers
    All_R_Tib_Marker_to_Cam = reshape(AllMarker_Rotation(:,:,:,TibiaID), [3, 3, Number_Timestamps]);
    All_T_Tib_Marker_to_Cam = reshape(AllMarker_Translation(:,:,TibiaID), [3, Number_Timestamps]);
    All_R_Fib_Marker_to_Cam = reshape(AllMarker_Rotation(:,:,:,FibulaID), [3, 3, Number_Timestamps]);
    All_T_Fib_Marker_to_Cam = reshape(AllMarker_Translation(:,:,FibulaID), [3, Number_Timestamps]);
    
    %% Get and apply coordinate transformation - native coordinate system is the CT coordinate system
    % Use SVD to calculate the Coordinate transformation based on the 
    % Motion Marker coordiantes measured in the camera and segmented on the CT
    [R_CamtoCT, t_CamtoCT] = Get_CoordinateTransformation_SVD(MarkerPos_Cam, MarkerPos_CT); % Move from Camera to CT Coordinate System
    
    % Transform Marker Motion Data to CT Coordinate System
    [All_R_Tib_Marker_to_CT, All_T_Tib_Marker_to_CT] = ...
        Connect_CoordinateTransformation(All_R_Tib_Marker_to_Cam, All_T_Tib_Marker_to_Cam, R_CamtoCT, t_CamtoCT);
    [All_R_Fib_Marker_to_CT, All_T_Fib_Marker_to_CT] = ...
        Connect_CoordinateTransformation(All_R_Fib_Marker_to_Cam, All_T_Fib_Marker_to_Cam, R_CamtoCT, t_CamtoCT);
    
    %% Prepare Motion application in the CT system through the residual motion incl. quality assurance
    % Calculate Residual motion (i.e., what is the marker movement in
    % timeframe t vs. a reference timeframe t_0
    [All_Residual_Rotation_Tib_CT, ~, All_Residual_Translation_Tib_CT, RotCenter_Tib_CT] = ...
        Calculate_Residual_Motion(All_R_Tib_Marker_to_CT, All_T_Tib_Marker_to_CT, CT_Timestamp);
    [All_Residual_Rotation_Fib_CT, ~, All_Residual_Translation_Fib_CT, RotCenter_Fib_CT] = ...
        Calculate_Residual_Motion(All_R_Fib_Marker_to_CT, All_T_Fib_Marker_to_CT, CT_Timestamp);
    
    % Quality Assurance for Rotation Matrices - check, that they are indeed orthonormal and with det 1
    % QualityAssurance_RotMat(PlotDIR, {All_Residual_Rotation_Tib_CT, All_Residual_Rotation_Fib_CT}, {'Tibia', 'Fibula'});   
    
    %% Initialize arrays
    % Initialize output arrays
    dataDir_CT_full = [Segmentation_OutputDIR '/MotionModel_02/CTSystem_fullmotion/'];
    createDirIfNotExist(dataDir_CT_full);
    dataDir_CT_TibFix = [Segmentation_OutputDIR '/MotionModel_02/CTSystem_fixedTib/'];
    createDirIfNotExist(dataDir_CT_TibFix);
    AntTibDist = zeros(1, Number_Timestamps);
    ScrewDistance = zeros(1, Number_Timestamps);
    
    
    %% Apply motion
    for timestamp = 1:Number_Timestamps
        % Apply motion on Tibia and Fibula and calculate AD at timestamp 
        Moved_Tib_PoI_CT = ApplyMotion_Points(Tib_PoI_CT, All_Residual_Translation_Tib_CT(:, timestamp), All_Residual_Rotation_Tib_CT(:, :, timestamp), RotCenter_Tib_CT,'normal');
        Moved_Tib_Points_CT = ApplyMotion_Points(Tib_Points_CT, All_Residual_Translation_Tib_CT(:, timestamp), All_Residual_Rotation_Tib_CT(:, :, timestamp), RotCenter_Tib_CT,'normal');
        Moved_Fib_Points_CT = ApplyMotion_Points(Fib_Points_CT, All_Residual_Translation_Fib_CT(:, timestamp), All_Residual_Rotation_Fib_CT(:, :, timestamp), RotCenter_Fib_CT,'normal');
        % [AntTibDist(timestamp), fibPoI, index] = Calculate_NearestNeighbor(Moved_Tib_PoI_CT, Moved_Fib_Points_CT, 'fixed z');
        
        % Apply Tibia motion backwards on Fibula
        TwiceMovedPoints_Fib = ApplyMotion_Points(Moved_Fib_Points_CT, All_Residual_Translation_Tib_CT(:, timestamp), All_Residual_Rotation_Tib_CT(:, :, timestamp), RotCenter_Tib_CT,'inv');
        [AntTibDist(timestamp), fibPoI2, index2] = Calculate_NearestNeighbor(Tib_PoI_CT, TwiceMovedPoints_Fib, 'fixed z');
        
        % save full motion in CT frame
        Tib_Label = sprintf('Tib_Seg_%04d.mat', timestamp);
        Tib_PointsSaveName = fullfile(dataDir_CT_full, Tib_Label); % Construct full file path
        Tib_PoI_Label = sprintf('Tib_PoI_%04d.mat', timestamp);
        Tib_PoISaveName = fullfile(dataDir_CT_full, Tib_PoI_Label); % Construct full file path
        Fib_Label = sprintf('Fib_Seg_%04d.mat', timestamp);
        Fib_PointsSaveName = fullfile(dataDir_CT_full, Fib_Label); % Construct full file path
        save(Tib_PointsSaveName, 'Moved_Tib_Points_CT');
        save(Tib_PoISaveName, 'Moved_Tib_PoI_CT');
        save(Fib_PointsSaveName, 'Moved_Fib_Points_CT');

        % save motion wrt Tibia in CT frame     
        Tib_Label = sprintf('Tib_Seg_%04d.mat', timestamp);
        Tib_PointsSaveName = fullfile(dataDir_CT_TibFix, Tib_Label); % Construct full file path
        Tib_PoI_Label = sprintf('Tib_PoI_%04d.mat', timestamp);
        Tib_PoISaveName = fullfile(dataDir_CT_TibFix, Tib_PoI_Label); % Construct full file path
        Fib_Label = sprintf('Fib_Seg_%04d.mat', timestamp);
        Fib_PointsSaveName = fullfile(dataDir_CT_TibFix, Fib_Label); % Construct full file path
        save(Tib_PointsSaveName, 'Tib_Points_CT');
        save(Tib_PoISaveName, 'Tib_PoI_CT');
        save(Fib_PointsSaveName, 'TwiceMovedPoints_Fib');

        % Apply motion on Screws and calculate distance at timestamp
        Moved_Tib_Screws_CT = ApplyMotion_Points(Tib_Screws_CT, All_Residual_Translation_Tib_CT(:, timestamp), All_Residual_Rotation_Tib_CT(:, :, timestamp), RotCenter_Tib_CT,'normal');
        Moved_Fib_Screws_CT = ApplyMotion_Points(Fib_Screws_CT, All_Residual_Translation_Fib_CT(:, timestamp), All_Residual_Rotation_Fib_CT(:, :, timestamp), RotCenter_Fib_CT,'normal');
        ScrewDistance(timestamp) = norm(Moved_Tib_Screws_CT - Moved_Fib_Screws_CT);


    end
end


function [t_0] = Get_CT_Timestamp(MotionDirection, N_t)
    switch lower(MotionDirection)  % Convert MotionDirection to lowercase for consistency
        case 'forward'
            t_0 = 1;  % Reference point for forward motion
        case 'backwards'
            t_0 = N_t;  % Reference point for backward motion
        otherwise
            error('Unsupported motion direction');  % Terminate execution
    end
end

function [] = QualityAssurance_Geometry(MarkersMeasured, All_Geometry)
    MarkerCheck = (All_Geometry - 10^7) /10; %for this experiment geometry is in the form 1000xxx0, where xxx is the marker name (e.g. 299)
    if  sum(abs(MarkersMeasured - MarkerCheck)) == 0
        return
    else
        error('Missmatch between measured and expected geometries')
    end
end
