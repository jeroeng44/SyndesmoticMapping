function [All_R_connect, All_t_connect] = Connect_CoordinateTransformation(All_R1, All_t1, All_R2, All_t2)
    %% INPUT:
    % All_Orientation: A 3x3xN matrix containing N orientation matrices for the markers.
    % All_Position: A 3xN matrix containing N position vectors for the markers.
    % R: A 3x3xM rotation matrix for the coordinate transformation.
    % t: A 3x1xM translation vector for the coordinate transformation.
    %% OUTPUT:
    % Transformed_All_Orientation: A 3x3xN matrix containing transformed orientation matrices.
    % Transformed_All_Position: A 3xN matrix containing transformed position vectors.
    %% DESCRIPTION:
    % This function applies a coordinate transformation to the marker orientations and positions.
    % The transformation is defined by the rotation matrix R and the translation vector t.
    
    % Validate input dimensions
    % assert(size(All_Orientation, 3) == size(All_Position, 2), 'Mismatch in the number of timestamps for orientation and position.');
    % assert(all(size(R) == [3, 3]), 'Rotation matrix R must be 3x3.');
    % assert(size(t, 1) == 3 && size(t, 2) == 1, 'Translation vector t must be 3x1.');
    
    N = size(All_R1, 3);
    M = size(All_R2, 3);

    if M == 1 & N>1
        [All_R2, All_t2] = Fill_for_timestamps(All_R2, All_t2, N);
    elseif M>1 & N==1
        [All_R1, All_t1] = Fill_for_timestamps(All_R1, All_t1, M);
    elseif M==N
        %in this case nothing needs to be done
    else
        error('Dimension missmatch')
    end
    
    % Preallocate output arrays
    All_R_connect = zeros(size(All_R1));
    All_t_connect = zeros(size(All_t1));

    % Apply transformations
    for timestamp = 1:N
        % Transform orientation
        All_R_connect(:,:,timestamp) = All_R2(:,:,timestamp) * All_R1(:,:,timestamp);
        
        % Transform position
        All_t_connect(:,timestamp) = All_R2(:,:,timestamp) * All_t1(:,timestamp) + All_t2(:,timestamp);
    end
end


function [Filled_R, Filled_t] = Fill_for_timestamps(R, t, Length)
    Filled_R = R;
    Filled_t = t;
    for i = 1:Length
        Filled_R(:,:,i) = R;
        Filled_t(:,i) = t;
    end
end