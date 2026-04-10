function Markers= Get_MarkerNames_from_Leg_Measure_AD(Selected_Leg)
    % Process based on file extension
    switch lower(Selected_Leg)  % Convert to lowercase to handle case-insensitivity
        case 'right'
            Tibia_Marker = 302;
            Fibula_Marker = 314;
            Description = 'Right Tib: 302, Right Fib: 314';
        case 'left'
            Tibia_Marker = 301;
            % Tibia_Marker = 302;
            Fibula_Marker = 311;
            Description = 'Left Tib: 301, Left Fib: 311';
        otherwise
            error(['Unknown leg side: ' Selected_Leg]);
    end
    Markers = [Tibia_Marker, Fibula_Marker];
end