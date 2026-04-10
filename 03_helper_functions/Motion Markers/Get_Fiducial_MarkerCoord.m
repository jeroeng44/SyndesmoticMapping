function [Fid_MCoord] = Get_Fiducial_MarkerCoord(MarkerName)
    % Process based on MarkerName
    switch MarkerName
        case 301
            Fid_MCoord = Get_Fiducials301();
        case 302
            Fid_MCoord = Get_Fiducials302();
        case 311
            Fid_MCoord = Get_Fiducials311();
        case 314
            Fid_MCoord = Get_Fiducials314();
        case 320
            Fid_MCoord = Get_Fiducials320();
        case 'test'
            Fid_MCoord = Get_FiducialsTest();
            disp('succesfuul test')
        otherwise
            disp(strcat({'No geometry data for marker No. '},string(MarkerName)));
            error;
    end
end

function [Fiducials301] = Get_Fiducials301()
    F0_301 = [0, 0, 0]';
    F1_301 = [7.17727, 25.9789, 0]';
    F2_301 = [39.771, -23.6055, 0.118846]';
    F3_301 = [63.3197, 0, 0]';
    Fiducials301 = [F0_301, F1_301, F2_301, F3_301];

end

function [Fiducials302] = Get_Fiducials302()
    F0_302 = [0, 0, 0]'; %oben links
    F1_302 = [20.6364, 11.4081, 0]'; %oben oben
    F2_302 = [48.3866, -29.1686, 0.00785334]';
    F3_302 = [71.6347, 0, 0]';
    Fiducials302 = [F0_302, F1_302, F2_302, F3_302];
end

function [Fiducials311] = Get_Fiducials311()
    F0_311 = [0, 0, 0]'; %oben mitte
    F1_311 = [17.6624, 26.0719, 0]'; %links
    F2_311 = [31.5422, -6.57994, -0.286817]'; %oben rechts
    F3_311 = [53.2611, 0, 0]'; % unten rechts
    Fiducials311 = [F0_311, F1_311, F2_311, F3_311];
end

function [Fiducials314] = Get_Fiducials314()
    F0_314 = [0, 0, 0]'; %bottom right
    F1_314 = [4.54466, 19.686, 0]'; %bottom left
    F2_314 = [21.0385, -17.0787, 0.341082]'; %middle right
    F3_314 = [52.8379, 0, 0]'; %top
    Fiducials314 = [F0_314, F1_314, F2_314, F3_314];
end

function [Fiducials320] = Get_Fiducials320()
    F0_320 = [0, 0, 0]'; 
    F1_320 = [10.5925, 14.8775, 0]'; 
    F2_320 = [19.9401, 25.1831, 0.497592]'; %middle right
    F3_320 = [41.7631, 0, 0]'; %top
    Fiducials320 = [F0_320, F1_320, F2_320, F3_320];
end


function [FiducialsTest] = Get_FiducialsTest()
    F2_Test = [0.0709   -0.1346    1.0888]'; 
    F1_Test = [0.0830   -0.1338    1.0826]'; 
    F0_Test = [0.0982   -0.1276    1.0732]'; %middle right
    F3_Test = [0.0596   -0.1330    1.0568]'; %top
    FiducialsTest = [F0_Test, F1_Test, F2_Test, F3_Test]*10^3;
    
    % to be filled
end

