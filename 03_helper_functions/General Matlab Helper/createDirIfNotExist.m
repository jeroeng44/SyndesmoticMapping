function createDirIfNotExist(directoryPath)
    if ~exist(directoryPath, 'dir')
        mkdir(directoryPath);
        % disp(['Directory created: ', directoryPath]);
    else
        % disp(['Directory already exists: ', directoryPath]);
    end
end