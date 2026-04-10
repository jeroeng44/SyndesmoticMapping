function ResultsTable = Run_Main_Experiment01_MeasureAD_vs_Torque(Name)
%to run command Window: >> Run_Main_Experiment01_MeasureAD_vs_Torque("exp30")
%% Prepare required input
    % Ensure, that all the folders and supplementary information is added
    % in the function 'Prepare_Experiment01_Specifics_MeasureAD'
    [Motion_InputDir, Segmentation_InputDIR, OutputDir, MotionMarkers_measured, MotionMarkers_CTvisible, which_leg, Torque_FileName, Torque_Channel, Torque_PlotRange, MotionDirection] = ...
        Prepare_Experiment01_Specifics_MeasureAD(Name);
    
    Matlab_OutputDir = [OutputDir '/MatlabOutput_final/'];
    Segmentation_OutputDIR = [OutputDir '/SegmentationMotion/'];
    MotionModel1_available = false;
    MotionModel2_available = false;
    %% Show raw motion
    %not sure but maybe this can be commented out in order to safe
    %computation time

    Experiment01_Measure_RawMarkerMovement(Motion_InputDir, OutputDir)
    % 
    % pause
    close all
    %% Measure AD and Screw distance in two methods
    
    if Markers_visible_for_MotionMethod1(which_leg, MotionMarkers_CTvisible)
        [AntTibDist_CTtoMarker, ScrewDistance_CTtoMarker] = Measure_AD_01_CTtoMarker(Motion_InputDir, Segmentation_InputDIR, Segmentation_OutputDIR, ... % relevant DIRs
            MotionMarkers_measured, ... % markers within motion marker measurement
            which_leg); % which leg
            MotionModel1_available = true;
    else
        disp('Not enough data for motion method 1')
    end
    
    if size(MotionMarkers_CTvisible,2)>=3
        [AntTibDist_CTtoCam, ScrewDistance_CTtoCam] = Measure_AD_02_CTtoCam(Motion_InputDir, Segmentation_InputDIR, Segmentation_OutputDIR, ... % relevant DIRs
            MotionMarkers_measured, MotionMarkers_CTvisible, ...
            which_leg, MotionDirection);
        MotionModel2_available = true;
    else
        disp('Not enough data for motion method 2')
    end
    
    Both_MotionModels_available = (MotionModel1_available && MotionModel2_available);
    
    %% Read Torque data
    Torque = Read_TorqueData(Torque_FileName, Torque_Channel);
    Torque = Torque(2:end);% Otherwhise issues with dimensions...
    % [~, Torque_PlotRange] = findpeaks(-Torque);

    % Find index of maximum torque value
    [~, maxIdx] = max(Torque);

    %Find index of min Torque value % Find index of minimum torque value BEFORE the max
    [~, localMinIdx] = min(Torque(1:maxIdx-1));
    minIdx = localMinIdx;
    
    %Torque_PlotRange(1) = max(Torque_PlotRange(1) , 1);
    % Torque_PlotRange(2) = min(Torque_PlotRange(2) , size(Torque,1));
    Torque_PlotRange(1) = minIdx;
    Torque_PlotRange(2) = maxIdx; 
    
    fprintf('%s: Torque plot range is chosen between timestamp %d and %d.\n',Name, Torque_PlotRange(1), Torque_PlotRange(2));

    %% Create and save the Result Table
    Timestamp = (Torque_PlotRange(1):Torque_PlotRange(2))';
    Torque_used = Torque(Torque_PlotRange(1):Torque_PlotRange(2));

    % Preallocate empty arrays
    AD1 = zeros(0,1); 
    AD2 = zeros(0,1);

    if MotionModel1_available
        AD1 = AntTibDist_CTtoMarker(Torque_PlotRange(1):Torque_PlotRange(2));
    end
    if MotionModel2_available
        AD2 = AntTibDist_CTtoCam(Torque_PlotRange(1):Torque_PlotRange(2));
    end

    AD1 = AD1';
    AD2 = AD2';

    % Handle table creation depending on which data is available
    if MotionModel1_available && MotionModel2_available
        ResultsTable = table(Timestamp, Torque_used, AD1, AD2, ...
            'VariableNames', {'Timestamp', 'Torque', 'AnteriorTibDist_Model1', 'AnteriorTibDist_Model2'});
    elseif MotionModel1_available
        ResultsTable = table(Timestamp, Torque_used, AD1, ...
            'VariableNames', {'Timestamp', 'Torque', 'AnteriorTibDist_Model1'});
    elseif MotionModel2_available
        ResultsTable = table(Timestamp, Torque_used, AD2, ...
            'VariableNames', {'Timestamp', 'Torque', 'AnteriorTibDist_Model2'});
    else
        ResultsTable = table();  % empty table
    end

    % Save if data exists
    if ~isempty(ResultsTable)
        % Add experiment name as a column
        ExpName = repmat({char(Name)}, height(ResultsTable), 1);
        ResultsTable = addvars(ResultsTable, ExpName, 'Before', 1, 'NewVariableNames', 'Experiment');

        % Convert Name to char in case it’s passed as a string
        Name_char = char(Name);

        % Build filenames
        CSV_FileName = fullfile(Matlab_OutputDir, ['AD_vs_Torque_Data_', Name_char, '.csv']);
        MAT_FileName = fullfile(Matlab_OutputDir, ['AD_vs_Torque_Data_', Name_char, '.mat']);

        % Save files
        writetable(ResultsTable, CSV_FileName);
        save(MAT_FileName, 'ResultsTable');
    end
    %% Compare motion methods screwdistance
    
    % if Both_MotionModels_available
    %     % both motion models
    %     fig = figure;
    %     plot(ScrewDistance_CTtoMarker)
    %     hold on
    %     plot(ScrewDistance_CTtoCam)
    %     % hold on
    %     % [x,y] =ControlMeasurementScrew(max(size(ScrewDistance_CTtoCam)));
    %     % plot(x,y,'r.','MarkerSize',3)
    %     xlabel('Timestamp [N]');
    %     ylabel('Distance between screws [mm]');
    %     ylim([128,137])
    %     legend('Motion model 1', 'Motion model 2', 'Control')
    %     title([Name,': Distance between screws against time']);
    %     subtitle('Both motion models')
    %     PlotName = 'ScrewDistance_vs_Time_bothmethods';
    %     saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
    %     saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    % elseif MotionModel1_available    
    %     fig = figure;
    %     plot(ScrewDistance_CTtoMarker)
    %     xlabel('Timestamp [N]');
    %     ylabel('Distance between screws [mm]');
    %     title([Name,': Distance between screws against time']);
    %     subtitle('Motion model 1 (CT registered to markers)')
    %     PlotName = 'ScrewDistance_vs_Time_motionmodel01';
    %     saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
    %     saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    % elseif MotionModel2_available    
    %     fig = figure;
    %     plot(ScrewDistance_CTtoCam)
    %     xlabel('Timestamp [N]');
    %     ylabel('Distance between screws [mm]');
    %     title([Name,': Distance between screws against time']);
    %     subtitle('Motion model 2 (CT registered to camera)')
    %     PlotName = 'ScrewDistance_vs_Time_motionmodel02';
    %     saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
    %     saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    % end
    
    %% Compare motion methods AD
    
    if Both_MotionModels_available
        % both motion models
        fig = figure;
        plot(AntTibDist_CTtoMarker)
        hold on
        plot(AntTibDist_CTtoCam)
        xlabel('Timestamp [N]');
        ylabel('Anterior Tibifiular Distance [mm]');
        legend('Motion model 1', 'Motion model 2')
        title([Name,': Anterior Tibifiular Distance against time']);
        subtitle('Both motion models')
        PlotName = 'AD_vs_Time_bothmethods';
        saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
        saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    elseif MotionModel1_available    
        fig = figure;
        plot(AntTibDist_CTtoMarker)
        xlabel('Timestamp [N]');
        ylabel('Anterior Tibifiular Distance [mm]');
        title([Name,': Anterior Tibifiular Distance against time']);
        subtitle('Motion model 1 (CT registered to markers)')
        PlotName = 'AD_vs_Time_motionmodel01';
        saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
        saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    elseif MotionModel2_available    
        fig = figure;
        plot(AntTibDist_CTtoCam)
        xlabel('Timestamp [N]');
        ylabel('Anterior Tibifiular Distance [mm]');
        title([Name,': Anterior Tibifiular Distance against time']);
        subtitle('Motion model 2 (CT registered to camera)')
        PlotName = 'AD_vs_Time_motionmodel02';
        saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
        saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    end
    
    %% Plot Torque
    fig = figure;
    plot(Torque)
    xlabel('Timestamp [s]');
    ylabel('Torque [Nm]');
    title([Name,': Torque against time']);
    PlotName = 'Torque_vs_Time';
    saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
    saveas(fig,[Matlab_OutputDir,PlotName,'.png']);

    %% Analyze and plot AD vs. Torque
        
    if MotionModel1_available    
        % motion model 1: CT registered to markers
        fig = figure;
        plot(Torque(Torque_PlotRange(1):Torque_PlotRange(2)),AntTibDist_CTtoMarker(Torque_PlotRange(1):Torque_PlotRange(2)),'.', 'Color' , '#0072BD');
        xlabel('Torque [Nm]');
        ylabel('Anterior Tibifiular Distance [mm]');
        title([Name,': Anterior Tibifiular Distance against Torque']);
        subtitle(sprintf('Motion model 1 (CT registered to markers); Considered timestamps %d to %d.\n',Torque_PlotRange(1), Torque_PlotRange(2)))
        % title('Anterior Tibifiular Distance against Torque');
        % subtitle({[Name,', motion model 1 (CT registered to markers)'],...
        %     sprintf('Relevant timestamps: %d to %d.\n',Torque_PlotRange(1), Torque_PlotRange(2))})
        PlotName = 'AD_vs_Torque_motionmodel01';
        saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
        saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    end
    if MotionModel2_available
        % motion model 2: CT registered to camera
        fig = figure;
        plot(Torque(Torque_PlotRange(1):Torque_PlotRange(2)),AntTibDist_CTtoCam(Torque_PlotRange(1):Torque_PlotRange(2)),'.', 'Color' , '#D95319');
        xlabel('Torque [Nm]');
        ylabel('Anterior Tibifiular Distance [mm]');
        title([Name,': Anterior Tibifiular Distance against Torque']);
        subtitle(sprintf('Motion model 2 (CT registered to camera); Considered timestamps %d to %d.\n',Torque_PlotRange(1), Torque_PlotRange(2)))
        % title('Anterior Tibifiular Distance against Torque');
        % subtitle({[Name,', motion model 2 (CT registered to camera)'],...
            % sprintf('Relevant timestamps: %d to %d.\n',Torque_PlotRange(1), Torque_PlotRange(2))})
        PlotName = 'AD_vs_Torque_motionmodel02';
        saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
        saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    end
    
    if Both_MotionModels_available
        % both motion models
        fig = figure;
        plot(Torque(Torque_PlotRange(1):Torque_PlotRange(2)),AntTibDist_CTtoMarker(Torque_PlotRange(1):Torque_PlotRange(2)),'.', 'Color' , '#0072BD');
        hold on
        plot(Torque(Torque_PlotRange(1):Torque_PlotRange(2)),AntTibDist_CTtoCam(Torque_PlotRange(1):Torque_PlotRange(2)),'.', 'Color' , '#D95319');
        xlabel('Torque [Nm]');
        ylabel('Anterior Tibifiular Distance [mm]');
        legend('Motion model 1', 'Motion model 2')
        title([Name,': Anterior Tibifiular Distance against Torque']);
        subtitle(sprintf('Both motion models; Considered timestamps %d to %d.\n',Torque_PlotRange(1), Torque_PlotRange(2)))
        PlotName = 'AD_vs_Torque_bothmethods';
        saveas(fig,[Matlab_OutputDir,PlotName,'.pdf']);
        saveas(fig,[Matlab_OutputDir,PlotName,'.fig']);
        saveas(fig,[Matlab_OutputDir,PlotName,'.png']);
    end
end


function [Concat_MarkersAvaialble] = Markers_visible_for_MotionMethod1(which_leg, MotionMarkers_CTvisible)
    MotionMarkers_CTrequired = Get_MarkerNames_from_Leg_Measure_AD(which_leg);
    [MarkersAvaialble, ~] = ismember(MotionMarkers_CTrequired, MotionMarkers_CTvisible);
    Concat_MarkersAvaialble = MarkersAvaialble(1) & MarkersAvaialble(2);
end



function [Torque] = Read_TorqueData(FileName_Torque, relevantChannel)
    % Read the CSV file into a table
    TorqueData = readtable(FileName_Torque);
    switch lower(relevantChannel)
        case 'channel1'
            Torque = TorqueData.channel1;
        case 'channel2'
            Torque = TorqueData.channel2;
        otherwise
            error('Invalid channel selected');
    end
end

function [x,y] = ControlMeasurementScrew(maximum)
    y1 = 131.0469174;
    y2 = 134.885472;
    y3 = 130.8374199;
    x1 = linspace(0,40,40);
    x2 = linspace(80,150,70);
    x3 = linspace(160,maximum,40);
    x = [x1, x2, x3];
    y = [x1*0+y1, x2*0+y2, x3*0+y3];
end
