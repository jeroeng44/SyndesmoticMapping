function outputGifFile = GIFCreator(frameDir, outputGifFile, framePattern, frameRate)
%GIFCREATOR Create an animated GIF from a sequence of PNG frames.
%   outputGifFile = GIFCreator(frameDir)
%   outputGifFile = GIFCreator(frameDir, outputGifFile, framePattern, frameRate)
%
% Expected inputs:
%   frameDir      Directory containing exported PNG frames.
%   outputGifFile Path to the output GIF. Defaults to <frameDir>/output_video.gif.
%   framePattern  Glob pattern for frames. Defaults to 'Frame_*.PNG'.
%   frameRate     GIF frame rate in frames per second. Defaults to 10.

    if nargin < 1 || strlength(string(frameDir)) == 0
        frameDir = uigetdir(pwd, 'Select frame directory');
        if isequal(frameDir, 0)
            error('No frame directory selected.');
        end
    end

    if nargin < 2 || strlength(string(outputGifFile)) == 0
        outputGifFile = fullfile(frameDir, 'output_video.gif');
    end

    if nargin < 3 || strlength(string(framePattern)) == 0
        framePattern = 'Frame_*.PNG';
    end

    if nargin < 4 || isempty(frameRate)
        frameRate = 10;
    end

    imageFiles = dir(fullfile(frameDir, framePattern));
    if isempty(imageFiles)
        error('No frames matching "%s" were found in %s.', framePattern, frameDir);
    end

    imageFilenames = sort({imageFiles.name});
    h = waitbar(0, 'Converting images to GIF...');

    cleanupObj = onCleanup(@() closeWaitbarIfValid(h));

    for i = 1:numel(imageFilenames)
        img = imread(fullfile(frameDir, imageFilenames{i}));
        [indImg, colorMap] = rgb2ind(img, 256);

        if i == 1
            imwrite(indImg, colorMap, outputGifFile, 'gif', 'LoopCount', inf, ...
                'DelayTime', 1 / frameRate);
        else
            imwrite(indImg, colorMap, outputGifFile, 'gif', 'WriteMode', 'append', ...
                'DelayTime', 1 / frameRate);
        end

        waitbar(i / numel(imageFilenames), h);
    end

    fprintf('GIF creation complete: %s\n', outputGifFile);
end

function closeWaitbarIfValid(h)
    if ~isempty(h) && isvalid(h)
        close(h);
    end
end
