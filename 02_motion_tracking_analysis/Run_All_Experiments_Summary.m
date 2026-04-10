function summaryResults = Run_All_Experiments_Summary(experimentList, summaryOutputDir)
%RUN_ALL_EXPERIMENTS_SUMMARY Run the main analysis for configured experiments.
%   summaryResults = Run_All_Experiments_Summary()
%   summaryResults = Run_All_Experiments_Summary(experimentList)
%   summaryResults = Run_All_Experiments_Summary(experimentList, summaryOutputDir)
%
% If experimentList is omitted, all experiments from
% config/experiment_registry.csv are processed.

    registryFile = fullfile(fileparts(mfilename('fullpath')), 'config', 'experiment_registry.csv');
    registry = readtable(registryFile, 'TextType', 'string');

    if nargin < 1 || isempty(experimentList)
        experimentList = cellstr(registry.experiment)';
    end

    if nargin < 2 || strlength(string(summaryOutputDir)) == 0
        repoRoot = fileparts(fileparts(mfilename('fullpath')));
        summaryOutputDir = fullfile(repoRoot, '05_figures', 'generated_tables');
    end

    createDirIfNotExist(summaryOutputDir);
    summaryResults = table();

    for i = 1:numel(experimentList)
        Name = experimentList{i};
        fprintf('\n==> Running experiment: %s\n', Name);

        try
            ResultsTable = Run_Main_Experiment01_MeasureAD_vs_Torque(Name);

            if istable(ResultsTable) && height(ResultsTable) > 0
                if any(strcmp('Experiment', ResultsTable.Properties.VariableNames))
                    summaryResults = [summaryResults; ResultsTable]; %#ok<AGROW>
                else
                    warning('ResultsTable for %s has no "Experiment" column.', Name);
                end
            else
                warning('No results were generated for %s.', Name);
            end
        catch ME
            warning('Error in %s: %s', Name, ME.message);
        end
    end

    summaryFileName = fullfile(summaryOutputDir, 'Summary_AllExperiments.csv');
    writetable(summaryResults, summaryFileName);
    fprintf('\nSummary saved to: %s\n', summaryFileName);
end
