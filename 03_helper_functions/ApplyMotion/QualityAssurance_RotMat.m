function [] = QualityAssurance_RotMat(PlotDIR, Set_Matrices, Set_Names)
% function [] = QualityAssurance_RotMat(PlotDIR, matrices1, name1, matrices2, name2)
    
    disp(size(Set_Matrices))
    % Loop over each residual rotation matrix
    for i = 1:length(Set_Matrices)
        % Extract the i-th residual rotation matrix
        QualityAssurance_Single_RotMat(PlotDIR, Set_Matrices{i}, Set_Names{i});
    end
end


function [] = QualityAssurance_Single_RotMat(PlotDIR, matrices, Name)
%% INPUT:
%  matrices: (3x3xM array) A collection of M rotation matrices.
%  PlotDIR: (string) Directory path where output plots will be saved.
%  Name: (string) The name used to label the saved plots.

%% OUTPUT:
%  No direct output. The function saves a figure with the quality assurance results.

%% DESCRIPTION:
%  This function performs quality assurance on a series of rotation matrices by checking their orthonormality 
%  and computing their determinants. It generates plots to visualize the orthonormality errors and 
%  determinant values, highlighting any reflection matrices (where the determinant is negative).

    % Input validation
    if ndims(matrices) ~= 3 || size(matrices, 1) ~= 3 || size(matrices, 2) ~= 3
        error('Input matrices must have dimensions (3,3,M).');
    end

    % Initialize arrays to store orthonormality errors and determinant signs
    errors = zeros(1, size(matrices, 3));  % Array for orthonormality errors
    dets = zeros(1, size(matrices, 3));    % Array for determinants

    % Loop through each matrix and compute the error and determinant
    for i = 1:size(matrices, 3)
        A = matrices(:,:,i);  % Extract the i-th rotation matrix
        I_approx = A' * A;    % Compute A^T * A
        error = norm(I_approx - eye(size(A)), 'fro');  % Frobenius norm of the difference
        errors(i) = error;    % Store the orthonormality error
        dets(i) = det(A);     % Store the determinant
    end

    % Create a figure with two subplots
    fig = figure;

    % Plot the orthonormality errors
    subplot(2, 1, 1);
    bar(errors);  % Bar plot of errors
    xlabel('Timestamp [N]');
    ylabel({'Orthonormality Error', '\(\|A^T A - I\|_{\mathrm{Fro}}\)'}, 'Interpreter', 'latex');
    title('Quality assurance: Orthonormality');
    epsilon = 1e-6;  % Acceptance threshold
    ylim([0, max(1.25 * epsilon, max(errors))]);  % Set y-axis limits
    yline(epsilon, '--r', 'Acceptance threshold = $10^{-6}$', 'LabelHorizontalAlignment', 'left', 'Interpreter', 'latex');  % Threshold line

    % Plot the determinant values
    subplot(2, 1, 2);
    bar(dets);  % Bar plot of determinants
    xlabel('Timestamp [N]');
    ylim([-1.5, 1.5]);  % Set y-axis limits for determinants
    ylabel('Determinant');
    title('Quality assurance: Determinant');

    % Highlight reflection matrices
    hold on;
    reflections = find(dets < 0);  % Find indices where det(A) < 0
    scatter(reflections, dets(reflections), 100, 'r', 'filled');  % Mark reflections in red
    hold off;
    
    % Save the figure
    PlotName = strcat('QualityAssurance_Rotation_', Name);  % Construct plot name
    saveas(fig, fullfile(PlotDIR, [PlotName, '.pdf']));  % Save as PDF
    saveas(fig, fullfile(PlotDIR, [PlotName, '.png']));  % Save as PNG
end