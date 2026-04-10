function [Fiducials_Opt] = Optimize_Fiducials(Fiducials, MarkerName, TakePause)
    Reference = Get_Fiducial_MarkerCoord(MarkerName);
    % Define the fixed point P1
    P1 = Fiducials(:,1);  % Coordinates of P1
    
    % Predefined distances between the points
    d12 = norm(Reference(:,1) - Reference(:,2));  % Distance between P1 and P2
    d13 = norm(Reference(:,1) - Reference(:,3));  % Distance between P1 and P3
    d14 = norm(Reference(:,1) - Reference(:,4));  % Distance between P1 and P4
    d23 = norm(Reference(:,2) - Reference(:,3));  % Distance between P2 and P3
    d24 = norm(Reference(:,2) - Reference(:,4));  % Distance between P2 and P4
    d34 = norm(Reference(:,3) - Reference(:,4));  % Distance between P3 and P4
    
    % Initial guess for P2, P3, and P4 (with noise)
    initial_guess = Fiducials(:,2:end);
    % Flatten initial guess to a single column vector for optimization
    initial_guess_flat = initial_guess(:);
    
    % Set the bounds to restrict P2, P3, and P4 to be within +/- 1 of the initial guesses
    lb = initial_guess_flat - 0.7;  % Lower bounds
    ub = initial_guess_flat + 0.7;  % Upper bounds
    
    % Objective function to minimize the error between the distances
    objective = @(P) sum([
        (norm(P(1:3) - P1) - d12)^2,  % Distance P2-P1
        (norm(P(4:6) - P1) - d13)^2,  % Distance P3-P1
        (norm(P(7:9) - P1) - d14)^2,  % Distance P4-P1
        (norm(P(1:3) - P(4:6)) - d23)^2,  % Distance P2-P3
        (norm(P(1:3) - P(7:9)) - d24)^2,  % Distance P2-P4
        (norm(P(4:6) - P(7:9)) - d34)^2   % Distance P3-P4
    ]);
    
    % Set optimization options
    options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');
    
    % Run the optimization
    P_opt = fmincon(objective, initial_guess_flat, [], [], [], [], lb, ub, [], options);
    [P_opt, fval, exitflag, output] = fmincon(objective, initial_guess_flat, [], [], [], [], lb, ub, [], options);
    if fval > 10
        error('Fiducials wrongly selected for marker "%s"', MarkerName)
    end



    % Reshape the optimized points back to 3xN format
    Fiducials_Opt = reshape(cat(1,P1,P_opt), [3, 4]);
    disp(MarkerName)
    if TakePause
        pause
    end
end