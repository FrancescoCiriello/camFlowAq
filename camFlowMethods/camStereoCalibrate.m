function camStereoCalibrate(obj,squaresize,numcalibrationimages)
% use camStereoCalibrate to acquire calibration images and
% evaluate a stereoscopic calibration

% deduce number of cameras
numCams = length(obj);

% start preview
if ishandle(obj(1).liveStream) == 1
    close(obj(1).liveStream.Parent.Parent)
end
fprintf('\nDefault preview mode loaded.\n')
for i = 1:length(obj)
    subplot(2,ceil(numCams/2),i)
    res = obj(i).camera.vid.VideoResolution;
    obj(i).liveStream = image(zeros(res(2),res(1)));
    set(gcf,'Visible','on')    % required to run in a live script
    set(gca,'visible','off')
    axis equal tight
    preview(obj(i).camera.vid, obj(i).liveStream);
    % reset preview status
    obj(i).previewStatus = 1;
    obj(i).advancedPreviewStatus = 0;
end

% dialog box start calibration
if nargin == 2 || nargin == 3
    answer = questdlg('Start checkerboard stereo calibration?','Yes', 'No');
    switch answer
        case 'Yes'
            fprintf('\nStarting stereo calibration...\n')
            
            % create calibration* folder ------------------
            dirOutputsCalib = dir('outputs/stereocalibration*');
            calibNumber = numel(dirOutputsCalib);
            expName = ['stereocalibration' num2str(calibNumber+1)];
            mkdir(['outputs/' expName]);
            addpath(['outputs/' expName])
            
            for k = 1:numCams
                mkdir(['outputs/' expName '/cam' num2str(k)])
                addpath(['outputs/' expName '/cam' num2str(k)])
            end
            
            % acquire 10 images for calibration -----------
            if nargin == 3
                numCalibrationImages = numcalibrationimages;
            else
                numCalibrationImages = 10;
            end
            for i = 1:numCalibrationImages
                set(obj(1).liveStream.Parent.Parent,'color',[0.95 0.95 0.95])
                textImg = text(0,-400,['\bf{Image #' num2str(i) '/ ' num2str(numCalibrationImages) '}'],'Color','red','FontSize',14);
                for j = 1:4
                    textAq = text(0,-200,['Acquiring image group in ' num2str(4-j)],'Color','red','FontSize',14);
                    pause(1)
                    drawnow
                    delete(textAq)
                end
                for k = 1:numCams
                    calibrationImage(:,:,k) = getsnapshot(obj(k).camera.vid);
                end
                set(obj(1).liveStream.Parent.Parent,'color','w')
                textAq = text(0,-100,'Acquired.');
                drawnow
                pause(1)
                delete(textImg)
                delete(textAq)
                for k = 1:numCams
                    imwrite(calibrationImage(:,:,k),['outputs/' expName '/cam' num2str(k) '/stereoCalibrationImage' num2str(i) '.tif'])
                end
            end
            set(obj(1).liveStream.Parent.Parent,'color',[0.9 0.9 0.9])
            
            % evaluate calibration from images ------------
            fprintf('\nEvaluating calibration...\n')
            
            % define images to process
            for k = 1:numCams
                imageDirectory = dir(['outputs/' expName '/cam' num2str(k) '/stereoCalibrationImage*.tif']);
                imageNumber = numel(imageDirectory);
                for i = 1:imageNumber
                    imageFileName = imageDirectory(i).name;
                    imageFileNames{i} = imageFileName;
                end
                stereoImageFileNames{k} = imageFileNames;
            end
            
            % detect checkerboards in images
            fprintf('\nDetecting checkerboard points...\n')
            [imagePoints, boardSize, imagesUsed] = detectCheckerboardPoints(stereoImageFileNames{1:numCams});
            for k = 1:numCams
                stereoImageFileNames{k} = stereoImageFileNames{k}(imagesUsed);
            end
            
            % read the first image to obtain image size
            originalImage = imread(stereoImageFileNames{1}{1});
            [mrows, ncols, ~] = size(originalImage);
            
            % generate world coordinates of the corners of the squares
            worldPoints = generateCheckerboardPoints(boardSize, squaresize);
            
            % calibrate the camera
            fprintf('\nEstimating camera parameters...\n')
            % Calibrate the camera
            [stereoParams, pairsUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
                'EstimateSkew', true, 'EstimateTangentialDistortion', true, ...
                'NumRadialDistortionCoefficients', 3, 'WorldUnits', 'millimeters', ...
                'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', [], ...
                'ImageSize', [mrows, ncols]);
            
            % view reprojection errors
            reprojectionErrors=figure; showReprojectionErrors(stereoParams);
            
            % visualize pattern locations
            patternLocation=figure; showExtrinsics(stereoParams, 'CameraCentric');
            
            % display parameter estimation errors
            displayErrors(estimationErrors, stereoParams);
            
            % estimate pixel size on first measurement plane
            for k = 1:numCams
                px1 = imagePoints(1,1,1,k);
                py1 = imagePoints(1,2,1,k);
                px2 = imagePoints(2,1,1,k);
                py2 = imagePoints(2,2,1,k);
                squareSizeInPx = sqrt( (px1-px2)^2 + (py1-py2)^2 );
                pxsize(k) = squaresize/squareSizeInPx;
            end
            
            % save calibration in obj.calibration
            
            fprintf('\nSaving camera parameters...\n')
            obj(1).stereoCalibration.pxSize = pxsize(1:numCams);
            obj(1).stereoCalibration.imageFileNames = stereoImageFileNames{k};
            obj(1).stereoCalibration.imagePoints = imagePoints;
            obj(1).stereoCalibration.boardSize = boardSize;
            obj(1).stereoCalibration.imagesUsed = imagesUsed;
            obj(1).stereoCalibration.originalImage = originalImage;
            obj(1).stereoCalibration.mrows = mrows;
            obj(1).stereoCalibration.ncols = ncols;
            obj(1).stereoCalibration.worldPoints = worldPoints;
            obj(1).stereoCalibration.stereoParams = stereoParams;
            obj(1).stereoCalibration.estimationErrors = estimationErrors;
            obj(1).stereoCalibration.reprojectionErrors = reprojectionErrors;
            obj(1).stereoCalibration.patternLocation = patternLocation;
            fprintf('\nStereo calibration complete.\n')
            
            
            
        case 'No'
            fprintf('\nStereo calibration cancelled.\n')
    end
else
    error('Wrong number of inputs.')
end

end