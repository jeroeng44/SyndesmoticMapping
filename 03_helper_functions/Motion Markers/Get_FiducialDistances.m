function [Dist] = Get_FiducialDistances(MarkerName)
    % Process based on MarkerName
    switch MarkerName
        case 301
            Dist = FiducialDistances_301();
        case 302
            Dist = FiducialDistances_302();
        case 311
            Dist = FiducialDistances_311();
        case 314
            Dist = FiducialDistances_314();
        otherwise
            disp(strcat({'No geometry data for marker No. '},string(MarkerName)));
            error;
    end

% if MarkerName == 301
%         Dist = FiducialDistances_301();
%     elseif MarkerName == 302
%         Dist = FiducialDistances_302();
%     elseif MarkerName == 311
%         Dist = FiducialDistances_311();
%     elseif MarkerName == 314
%         Dist = FiducialDistances_314();
%     else
%         disp(strcat({'No geometry data for marker No. '},string(MarkerName)));
%         error;
%     end
end

function [Distances_301] = FiducialDistances_301()
    F0_301 = [0, 0, 0]';
    F1_301 = [7.17727, 25.9789, 0]';
    F2_301 = [39.771, -23.6055, 0.118846]';
    F3_301 = [63.3197, 0, 0]';
%     Fiducials301 = [F0_301, F1_301, F2_301, F3_301];
%     Fiducial_ScatterPlot_withLabels(Fiducials301(1,:), Fiducials301(2,:), 'Fiducials 301');
    Distances_301= [sqrt(sum ((F0_301 - F1_301).^2)), sqrt(sum ((F0_301 - F2_301).^2)), sqrt(sum ((F0_301 - F3_301).^2))];
%     disp('Distances 301:')
%     disp(Distances_301)
end

function [Distances_302] = FiducialDistances_302()
    F0_302 = [0, 0, 0]'; %oben links
    F1_302 = [20.6364, 11.4081, 0]'; %oben oben
    F2_302 = [48.3866, -29.1686, 0.00785334]';
    F3_302 = [71.6347, 0, 0]';
%     Fiducials302 = [F0_302, F1_302, F2_302, F3_302];
%     Fiducial_ScatterPlot_withLabels(Fiducials302(1,:), Fiducials302(2,:), 'Fiducials 302');
    Distances_302= [sqrt(sum ((F0_302 - F1_302).^2)), sqrt(sum ((F0_302 - F2_302).^2)), sqrt(sum ((F0_302 - F3_302).^2))];
%     disp('Distances 302:')
%     disp(Distances_302)
end

function [Distances_311] = FiducialDistances_311()
    F0_311 = [0, 0, 0]'; %oben mitte
    F1_311 = [17.6624, 26.0719, 0]'; %links
    F2_311 = [31.5422, -6.57994, -0.286817]'; %oben rechts
    F3_311 = [53.2611, 0, 0]'; % unten rechts
%     Fiducials311 = [F0_311, F1_311, F2_311, F3_311];
%     Fiducial_ScatterPlot_withLabels(Fiducials311(1,:), Fiducials311(2,:), 'Fiducials 311');
    Distances_311= [sqrt(sum ((F0_311 - F1_311).^2)), sqrt(sum ((F0_311 - F2_311).^2)), sqrt(sum ((F0_311 - F3_311).^2))];
    % disp('Distances 311:')
    % disp(Distances_311)
end

function [Distances_314] = FiducialDistances_314()
    F0_314 = [0, 0, 0]'; %bottom right
    F1_314 = [4.54466, 19.686, 0]'; %bottom left
    F2_314 = [21.0385, -17.0787, 0.341082]'; %middle right
    F3_314 = [52.8379, 0, 0]'; %top
%     Fiducials314 = [F0_314, F1_314, F2_314, F3_314];
%     Fiducial_ScatterPlot_withLabels(Fiducials314(1,:), Fiducials314(2,:), 'Fiducials 314');
    Distances_314= [sqrt(sum ((F0_314 - F1_314).^2)), sqrt(sum ((F0_314 - F2_314).^2)), sqrt(sum ((F0_314 - F3_314).^2))];
%     disp('Distances 314:')
%     disp(Distances_314)
end


function [] = Fiducial_ScatterPlot_withLabels(x,y,plot_title)
    figure;
    color = linspace(1,10,4);
    scatter(x, y,[],color)
    title(plot_title);
    b = [{'F0'}, {'F1'}, {'F2'}, {'F3'}]'; labels = cellstr(b);
    dx = 1; dy = 1; % displacement so the text does not overlay the data points
text(x+dx, y+dy, labels);
end
