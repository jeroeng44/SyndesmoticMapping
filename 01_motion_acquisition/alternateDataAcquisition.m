function alternateDataAcquisition_vSimple()
    % Initialize paths for dependencies and data output
    addpath(genpath(pwd)) 
    
    % DAQ Initialization and File Setup
    FileID_dqOutput = fopen("testxxx.bin", "w");  % Binary file for DAQ data
    csvFileID_tor = fopen("outputDatatorque.csv", "w");  % CSV file for torque data
    fprintf(csvFileID_tor, 'Timestamp,Channel1,Channel2\n');  % Write the header for storing the data in columns
    
    % Global variables for storing averaged channel data
    global averageChannel1 averageChannel2;
    averageChannel1 = 0;
    averageChannel2 = 0;

    % Initialize the DAQ device (NI DAQ)
    daq_session = initializeDAQ();  % Move DAQ initialization to a separate function
    
    % Callback for handling DAQ data processing
    daq_session.ScansAvailableFcn = @(src, event) dataCapture_vSimple(src, event, FileID_dqOutput);
    daq_session.ErrorOccurredFcn = @(src, event) disp(getReport(event.Error));  % Error handler

    disp('DAQ configuration initialized.');

    % Motion Tracking Initialization
    addScrewMarkers = true;  % If tracking screw markers, set this flag
    sn = initializeMotionTracking(addScrewMarkers);  % Move motion tracking to a separate function
    disp("Motion tracking initialized.");

    %% Main measurement
    
    % initialization
    totalDuration = 120;  % Total duration for data acquisition loop
    tic;  % Start timer
        
    while toc < totalDuration
        % Update the latestTimestamp with the current elapsed time
        latestTimestamp_Tor = toc;  % This captures the current time elapsed since tic was called

        % Call Software Analog Trigger Capture function
        fprintf('Running Software Analog Trigger Capture...Timestamp: %f', latestTimestamp_Tor);
        SoftwareAnalogTriggerCapture_vSimple(daq_session);
        
        % Log and print torque data in CSV files
        logData(csvFileID_tor, latestTimestamp_Tor, averageChannel1, averageChannel2);
        pause(0.1); % Add short pause if needed for hardware/software recovery
 
        latestTimestamp_Motion = toc;  % This captures the current time elapsed since tic was called

        % Call Motion Tracking with Markers function
        fprintf('Running Motion Tracking with Markers...Timestamp: %f', latestTimestamp_Motion);
        MotionTrackingWithMarkers_vSimple(s, sn, expectedMarkerIDs, dataDir, latestTimestamp_Motion);
        pause(0.1); % Add short pause if needed for hardware/software recovery
    end

    disp('Data acquisition completed.');
    % Close the CSV file
    fclose(csvFileID_tor);
end

function logData(csvFileID, timestamp, channel1, channel2)
    % Log averaged DAQ data to a CSV file, print what is saved
    fprintf('Average of the three latest data points for Channel 1: %f\n', channel1);
    fprintf('Average of the three latest data points for Channel 2: %f\n', channel2);
    fprintf(csvFileID, '%f,%f,%f\n', timestamp, channel1, channel2);
end

   function dq = initializeDAQ()
    % Set up the DAQ session and channels
    dq = daq('ni');
    ch1 = addinput(dq, 'Dev7', 0, 'Voltage');
    ch2 = addinput(dq, 'Dev7', 1, 'Voltage');
    % Set acquisition configuration for each channelz
    ch1.TerminalConfig = 'SingleEnded';
    ch2.TerminalConfig = 'SingleEnded';
    ch1.Range = [-10.0 10.0];
    ch2.Range = [-10.0 10.0];
    
    % Set voltage range and acquisition rate
    dq.Rate = 4;  % 4 scans per second data capture rate
    disp('DAQ initialized with 4 Hz sample rate.');
   end

function [s, sn, expectedMarkerIDs] = initializeMotionTracking(pathGeomFiles, addScrewMarkers)
    % Initialize marker files and expected marker IDs
    markerFiles = strings;
    expectedMarkerIDs = [];  % Initialize as empty

    % Always add RefMarkerBase
    markerFiles(end+1) = fullfile(pathGeomFiles, filesep, 'geometry10002990.ini');
    expectedMarkerIDs(end+1) = 10002990;

    % Conditionally add screw markers
    if addScrewMarkers
        markerFiles(end+1) = fullfile(pathGeomFiles, filesep, 'geometry10003020.ini'); % right Tib
        expectedMarkerIDs(end+1) = 10003020;

        markerFiles(end+1) = fullfile(pathGeomFiles, filesep, 'geometry10003140.ini'); % right fib
        expectedMarkerIDs(end+1) = 10003140;

        markerFiles(end+1) = fullfile(pathGeomFiles, filesep, 'geometry10003010.ini'); % left Tib
        expectedMarkerIDs(end+1) = 10003010;

        markerFiles(end+1) = fullfile(pathGeomFiles, filesep, 'geometry10003110.ini'); % left fib
        expectedMarkerIDs(end+1) = 10003110;
    end

    % Initialize FusionTrack and device
    s = FusionTrack();    % Always create a new FusionTrack object
    sn = s.devices;

    if isempty(sn)
        error('No devices detected');
    end

    % Load and set geometries
    for k = 1:length(markerFiles)
        geom = loadGeometry(markerFiles(k));
        s.setGeometry(sn(1), geom);  % Set geometry for the first device
    end

    sn = sn(1);  % Only use the first device
    disp("Motion tracking initialized.");
end
   