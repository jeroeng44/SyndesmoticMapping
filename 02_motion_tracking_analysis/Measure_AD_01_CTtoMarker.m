function [AntTibDist, ScrewDistance] = Measure_AD_01_CTtoMarker(Marker_InputDIR, CT_InputDIR, Segmentation_OutputDIR, MarkersMeasured, Selected_Leg)
    %% Function Descriptption
    %% INPUT:
    %   Marker_InputDIR - Directory containing marker data.
    %   CT_InputDIR - Directory containing CT data.
    %   MarkersMeasured - Motion markers in the setup (not necesarily visible on the CT)
    %   Selected_Leg - Selected leg for analysis.
    %   MotionDirection - A string indicating the motion direction; allowed values are 'forward' and 'backward'.
    %% OUTPUT:
    %   AntTibDist - Anterior tibiofibular distance over time.
    %   ScrewDistance - Distance between screws over time.
    %% DESCRIPTION:
    %   Anterior tibiofibular distance is calculated by
    %   -   Registering CT coordinate system to the two intrinsic marker systems (once for Tibia and once for Fibula)
    %   -   Moving the relevant points using the coordinate transformation between the intrinisc marker systems and the camera (i.e. motion model 1)
     
    %% Initialization reference motion
    % Get marker names and IDs for later use
    Leg_Markers = Get_MarkerNames_from_Leg_Measure_AD(Selected_Leg); % Pull marker names for the relevent leg, these are the markers we register the CT to
    [~, Leg_Markers_ID] = ismember(Leg_Markers, MarkersMeasured); % get respective marker IDs
    TibiaID = Leg_Markers_ID(1); 
    FibulaID = Leg_Markers_ID(2);
    
    %% Get CT Segmentation Data
    % Function Get_SegmentationData to get the relevant anatomy data
    % CT to be manually segmented previous to running the analysis scrip
    % Details in  "How-To-Presentation"
    [Tib_PoI_CT, Tib_Points_CT, Fib_Points_CT, Screws_CT, Fiducials_CT] = Get_SegmentationData_MeasureAD(CT_InputDIR, Leg_Markers);
    Tib_Screws_CT = Screws_CT(:, 1);
    Fib_Screws_CT = Screws_CT(:, 2);


%% Transformation to intrinsic marker system
    % Fiducial coordinates in both systems, the coordinate system is the marked by the ending (i.e., _CT means in the CT system)
    Tib_Fiducials_CT_unopt = Fiducials_CT(:,:,1); % Coordinates of the Fiducials of the Tibia marker as selcted on the CT
    Fib_Fiducials_CT_unopt = Fiducials_CT(:,:,2); % Coordinates of the Fiducials of the Fibula marker as selcted on the CT

    % Optional pause flag for inspecting fiducial optimization.
    TakePause = false; % Change to true if needed

    % optimize for correct geometry (we don't want to skew the registration points
    Tib_Fiducials_CT = Optimize_Fiducials(Tib_Fiducials_CT_unopt, Leg_Markers(1), TakePause)
    Fib_Fiducials_CT = Optimize_Fiducials(Fib_Fiducials_CT_unopt, Leg_Markers(2), TakePause)
    % get marker fiducials in the marker system
    Tib_Fiducials_Marker = Get_Fiducial_MarkerCoord(Leg_Markers(1)); % Coordinates of the Fiducials of the Tibia marker in its intrinsic system
    Fib_Fiducials_Marker = Get_Fiducial_MarkerCoord(Leg_Markers(2)); % Coordinates of the Fiducials of the Fibula marker in its intrinsic system
    
    % Coordinate transformation using SVD. Coord_Marker = R * Coord_CT + T
    [R_Tib_CT_to_Marker, T_Tib_CT_to_Marker] = Get_CoordinateTransformation_SVD(Tib_Fiducials_CT, Tib_Fiducials_Marker);
    [R_Fib_CT_to_Marker, T_Fib_CT_to_Marker] = Get_CoordinateTransformation_SVD(Fib_Fiducials_CT, Fib_Fiducials_Marker);
    
    
    % Get coordinates of the screws and the Fibula points in the marker system
    Tib_Screws_Marker = Apply_CoordinateTransformation_Points(Tib_Screws_CT, R_Tib_CT_to_Marker, T_Tib_CT_to_Marker, 'normal'); % coordinates of the tibia screw in the intrinsic marker system
    Fib_Screws_Marker = Apply_CoordinateTransformation_Points(Fib_Screws_CT, R_Fib_CT_to_Marker, T_Fib_CT_to_Marker, 'normal'); % coordinates of the fibula screw in the intrinsic fibula marker system
    Fib_Points_Marker = Apply_CoordinateTransformation_Points(Fib_Points_CT, R_Fib_CT_to_Marker, T_Fib_CT_to_Marker, 'normal'); % coordinates of the fibula segmentation in the intrinsic fibula marker system 
    Tib_Points_Marker = Apply_CoordinateTransformation_Points(Tib_Points_CT, R_Tib_CT_to_Marker, T_Tib_CT_to_Marker, 'normal'); % coordinates of the tibia segmentation in the intrinsic fibula marker system 
    Tib_PoI_Marker = Apply_CoordinateTransformation_Points(Tib_PoI_CT, R_Tib_CT_to_Marker, T_Tib_CT_to_Marker, 'normal'); % coordinates of the tibia PoI in the intrinsic fibula marker system 

    %% Get MotionMarker Data:
    % Here we pull all the motion marker data available
    % We can select the relevant data via the ID of the corresponding motion markers (see initialization)
    % AverageTracker indicates if we average over the 3 frames per timestamp (TRUE) or just take the first frame (FALSE)
    [All_Geometry, AllMarker_Rotation, AllMarker_Translation, ~, Number_Timestamps] = ...
        GetFolder_MotionMarker_Data(Marker_InputDIR, MarkersMeasured, false);
    %QualityAssurance_Geometry(MarkersMeasured, All_Geometry); %returns an error if no match with expected markers
    
    % Extract Motion Data for relevant markers (motion data in model 1,
    % means the coordinate transformation between the respective intrinsic
    % marker system and the camera system at time t
    All_R_Tib_Marker_to_Cam = reshape(AllMarker_Rotation(:,:,:,TibiaID), [3, 3, Number_Timestamps]);
    All_T_Tib_Marker_to_Cam = reshape(AllMarker_Translation(:,:,TibiaID), [3, Number_Timestamps]);
    All_R_Fib_Marker_to_Cam = reshape(AllMarker_Rotation(:,:,:,FibulaID), [3, 3, Number_Timestamps]);
    All_T_Fib_Marker_to_Cam = reshape(AllMarker_Translation(:,:,FibulaID), [3, Number_Timestamps]);

%     % Quality Assurance for Rotation Matrices - check, that they are indeed orthonormal and with det 1
%     QualityAssurance_RotMat(PlotDIR, {All_R_Tib_Marker_to_Cam, All_R_Fib_Marker_to_Cam}, {'Tibia', 'Fibula'});   

    %% Initialize arrays
    % Initialize output arrays
    dataDir_Cam_full = [Segmentation_OutputDIR '/MotionModel_01/CamSystem_fullmotion/'];
    createDirIfNotExist(dataDir_Cam_full);
    dataDir_CT_TibFix = [Segmentation_OutputDIR '/MotionModel_01/CTSystem_fixedTib/'];
    createDirIfNotExist(dataDir_CT_TibFix);


    AntTibDist = zeros(1, Number_Timestamps);
    ScrewDistance_Cam = zeros(1, Number_Timestamps);
    ScrewDistance_TibCT = zeros(1, Number_Timestamps);
    
    %% Apply motion
    for timestamp = 1:Number_Timestamps
        % Get transformations from Markers to Cam in this timestamp
        R_Tib_Marker_to_Cam = All_R_Tib_Marker_to_Cam(:,:,timestamp);
        T_Tib_Marker_to_Cam = All_T_Tib_Marker_to_Cam(:,timestamp);
        
        R_Fib_Marker_to_Cam = All_R_Fib_Marker_to_Cam(:,:,timestamp);
        T_Fib_Marker_to_Cam = All_T_Fib_Marker_to_Cam(:,timestamp);
        
        % Apply coordinate transformation to get scres and fibula points in the camera system
        Tib_Screws_Cam = Apply_CoordinateTransformation_Points(Tib_Screws_Marker, R_Tib_Marker_to_Cam, T_Tib_Marker_to_Cam, 'normal');
        Fib_Screws_Cam = Apply_CoordinateTransformation_Points(Fib_Screws_Marker, R_Fib_Marker_to_Cam, T_Fib_Marker_to_Cam, 'normal');
        Fib_Points_Cam = Apply_CoordinateTransformation_Points(Fib_Points_Marker, R_Fib_Marker_to_Cam, T_Fib_Marker_to_Cam, 'normal');
        Tib_Points_Cam = Apply_CoordinateTransformation_Points(Tib_Points_Marker, R_Tib_Marker_to_Cam, T_Tib_Marker_to_Cam, 'normal');
        Tib_PoI_Cam = Apply_CoordinateTransformation_Points(Tib_PoI_Marker, R_Tib_Marker_to_Cam, T_Tib_Marker_to_Cam, 'normal');
        
        % save moved points in camera system
        Tib_Label = sprintf('Tib_Seg_%04d.mat', timestamp);
        Tib_PointsSaveName = fullfile(dataDir_Cam_full, Tib_Label); % Construct full file path
        Tib_PoI_Label = sprintf('Tib_PoI_%04d.mat', timestamp);
        Tib_PoISaveName = fullfile(dataDir_Cam_full, Tib_PoI_Label); % Construct full file path
        Fib_Label = sprintf('Fib_Seg_%04d.mat', timestamp);
        Fib_PointsSaveName = fullfile(dataDir_Cam_full, Fib_Label); % Construct full file path
        save(Tib_PointsSaveName, 'Tib_Points_Cam');
        save(Tib_PoISaveName, 'Tib_PoI_Cam');
        save(Fib_PointsSaveName, 'Fib_Points_Cam');
        
        ScrewDistance_Cam(timestamp) = norm(Tib_Screws_Cam - Fib_Screws_Cam);
        
        % Transform Fib_Screws_Cam back to the original Tib CT and calculate the distance there 
        Fib_Screws_TibMarker = Apply_CoordinateTransformation_Points(Fib_Screws_Cam, R_Tib_Marker_to_Cam, T_Tib_Marker_to_Cam, 'inv');
        Fib_Screws_TibCT = Apply_CoordinateTransformation_Points(Fib_Screws_TibMarker, R_Tib_CT_to_Marker, T_Tib_CT_to_Marker, 'inv');
        ScrewDistance_TibCT(timestamp) = norm(Tib_Screws_CT - Fib_Screws_TibCT);
        
        % Transform Fib Segmentation back to the original Tib CT and calculate the AD there (easiest way to consider only one z slice on the CT)
        Fib_Points_TibMarker = Apply_CoordinateTransformation_Points(Fib_Points_Cam, R_Tib_Marker_to_Cam, T_Tib_Marker_to_Cam, 'inv');
        Fib_Points_TibCT = Apply_CoordinateTransformation_Points(Fib_Points_TibMarker, R_Tib_CT_to_Marker, T_Tib_CT_to_Marker, 'inv');
        [AntTibDist(timestamp), fibPoI, index] = Calculate_NearestNeighbor(Tib_PoI_CT, Fib_Points_TibCT, 'fixed z'); % Calculate AD via Fib_Points_TibCT and Tib_PoI_CT

        % save motion wrt Tibia in CT frame     
        Tib_Label = sprintf('Tib_Seg_%04d.mat', timestamp);
        Tib_PointsSaveName = fullfile(dataDir_CT_TibFix, Tib_Label); % Construct full file path
        Tib_PoI_Label = sprintf('Tib_PoI_%04d.mat', timestamp);
        Tib_PoISaveName = fullfile(dataDir_CT_TibFix, Tib_PoI_Label); % Construct full file path
        Fib_Label = sprintf('Fib_Seg_%04d.mat', timestamp);
        Fib_PointsSaveName = fullfile(dataDir_CT_TibFix, Fib_Label); % Construct full file path
        save(Tib_PointsSaveName, 'Tib_Points_CT');
        save(Tib_PoISaveName, 'Tib_PoI_CT');
        save(Fib_PointsSaveName, 'Fib_Points_TibCT');
    end

    % quality assurance via Screw distance 
    % Should be preserved across systems
    if max(abs(ScrewDistance_TibCT - ScrewDistance_Cam))>0.5
        error('Something is off witht he cooridnate transformations')
    end

    ScrewDistance = ScrewDistance_TibCT;
end


% function [Fiducials_Opt] = Optimize_Fiducials(Fiducials, MarkerName)
%     Reference = Get_Fiducial_MarkerCoord(MarkerName);
%     % Define the fixed point P1
%     P1 = Fiducials(:,1);  % Coordinates of P1
% 
%     % Predefined distances between the points
%     d12 = norm(Reference(:,1) - Reference(:,2));  % Distance between P1 and P2
%     d13 = norm(Reference(:,1) - Reference(:,3));  % Distance between P1 and P3
%     d14 = norm(Reference(:,1) - Reference(:,4));  % Distance between P1 and P4
%     d23 = norm(Reference(:,2) - Reference(:,3));  % Distance between P2 and P3
%     d24 = norm(Reference(:,2) - Reference(:,4));  % Distance between P2 and P4
%     d34 = norm(Reference(:,3) - Reference(:,4));  % Distance between P3 and P4
% 
%     % Initial guess for P2, P3, and P4 (with noise)
%     initial_guess = Fiducials(:,2:end);
%     % Flatten initial guess to a single column vector for optimization
%     initial_guess_flat = initial_guess(:);
% 
%     % Set the bounds to restrict P2, P3, and P4 to be within +/- 1 of the initial guesses
%     lb = initial_guess_flat - 0.7;  % Lower bounds
%     ub = initial_guess_flat + 0.7;  % Upper bounds
% 
%     % Objective function to minimize the error between the distances
%     objective = @(P) sum([
%         (norm(P(1:3) - P1) - d12)^2,  % Distance P2-P1
%         (norm(P(4:6) - P1) - d13)^2,  % Distance P3-P1
%         (norm(P(7:9) - P1) - d14)^2,  % Distance P4-P1
%         (norm(P(1:3) - P(4:6)) - d23)^2,  % Distance P2-P3
%         (norm(P(1:3) - P(7:9)) - d24)^2,  % Distance P2-P4
%         (norm(P(4:6) - P(7:9)) - d34)^2   % Distance P3-P4
%     ]);
% 
%     % Set optimization options
%     options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');
% 
%     % Run the optimization
%     P_opt = fmincon(objective, initial_guess_flat, [], [], [], [], lb, ub, [], options);
% 
%     % Reshape the optimized points back to 3xN format
%     Fiducials_Opt = reshape(cat(1,P1,P_opt), [3, 4]);
% end
