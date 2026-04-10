function [] = TestCoordinateRegistration()

    
    [~, CT_InputDIR, ~, ~, ~, ~, ~] = ...
    Prepare_Experiment01_Specifics_MeasureAD('Pilot05');
    MarkerOnCT = [301,302,311];
    
    
    % [~, CT_InputDIR, ~, ~, ~, ~, ~] = ...
    % Prepare_Experiment01_Specifics_MeasureAD('Pilot02');
    % MarkerOnCT = [302,314];


    %% Get CT Segmentation Data
    % CT segmentation input needs to be adapted to get the fiducials of the motion markers in focus
    [~, ~, ~, All_Fiducials_CT] = Get_SegmentationData_MeasureAD(CT_InputDIR, MarkerOnCT);
    
    
    %% Transformation to intrinsic marker system
    
    Reg_err = [0];
    Sel_err = [0];

    for i = 1:size(MarkerOnCT,2)
        % Fiducial coordinates in both systems
        Fiducials_CT = All_Fiducials_CT(:,:,i);
        Fiducials_Marker = Get_Fiducial_MarkerCoord(MarkerOnCT(i)); 
        % Fiducials_CT = Fiducials_Marker + 1000;
        % Coordinate transformation using SVD. Coord_Marker = R * Coord_CT + T
        [R_SVD, T_SVD] = Get_CoordinateTransformation(Fiducials_CT, Fiducials_Marker);
        
        Test_SVD_registration = Fiducials_Marker - Apply_CoordinateTransformation_Points(Fiducials_CT, R_SVD,T_SVD,'normal');
        Mean_Diff_registration = mean(sum(Test_SVD_registration.^2));
    
        
        Dist_CT = Fiducials_Distances(Fiducials_CT);
        Dist_Marker = Fiducials_Distances(Fiducials_Marker);
        
        Difference_Distances = mean((Dist_CT - Dist_Marker)).^2;
        Reg_err(i) = Mean_Diff_registration;
        Sel_err(i) = Difference_Distances;
    end
    
    close all
    figure
    plot(Reg_err,'*')
    title('Reg_err')
    figure
    plot(Sel_err,'*')
    title('Sel_err')
    figure
    plot(Sel_err, Reg_err,'*')
    title('Reg_err vs. Sel_err')

end


function [Distances] = Fiducials_Distances(Fiducials)
    Distances = [];
    index = 1;
    for i = 1:3
        for j = i+1:4
            diff = Fiducials(:,i) - Fiducials(:,j);
            Distances(index) = norm(diff);
            index = index + 1;
        end
    end
end


function [R, T] = Get_CoordinateTransformation_SVD_ICP(Points_A, Points_B);
    [R_SVD, T_SVD] = Get_CoordinateTransformation(Points_A, Points_B);

    Points_A_SVD = Apply_CoordinateTransformation_Points(Points_A, R_SVD,T_SVD,'normal');
    
    [R_ICP, T_ICP] = Get_CoordinateTransformation_ICP(Points_A_SVD, Points_B);


    [R,T] = Connect_CoordinateTransformation(R_SVD, T_SVD, R_ICP,T_ICP);
end




function [R, T] = Get_CoordinateTransformation_ICP(Points_A, Points_B);
    pc_A = pointCloud(Points_A');
    pc_B = pointCloud(Points_B');
    [tform, moved_A] = pcregistericp(pc_A, pc_B);
    R = (tform.R);
    T = (tform.Translation)';

end
