function camCalibrate(obj,calibrationmethod,squaresize,numcalibrationimages)
% use camCalibrate to preview the image and choose the ROI for the
% camera.
%
% See also IMLINE, PREVIEW.

% calibrate time
fps = obj.camera.src.AcquisitionFrameRate;
obj.calibration.dt = 1/fps;

% choose calibration method
validCalibrationMethods = ["line","dye","checker"];
validatestring(calibrationmethod,validCalibrationMethods);

% calibrate with user input
if nargin == 2 || nargin == 3 || nargin == 4
    if ishandle(obj.liveStream) == 1
        close(obj.liveStream.Parent.Parent)
    end
    fprintf('\nDefault preview mode loaded.\n')
    set(gcf,'Visible','on')    % required to run in a live script
    set(gca,'visible','off')
    res = obj.camera.vid.VideoResolution;
    obj.liveStream = image(zeros(res(2),res(1)));
    preview(obj.camera.vid, obj.liveStream);
    axis equal tight
    
    % line calibration
    if strcmp(calibrationmethod,'line') == 1 && nargin == 2
        % user-input for crop rectangle
        text1 = text(0,-100,'Draw line and double-click to confirm crop');
        cropLine = imline(gca);
        line = wait(cropLine);
        pxLineLength = sqrt( (line(3)-line(1))^2 + (line(4)-line(2))^2 );
        
        prompt = {'Line length in mm:'};
        dlgtitle = 'Line calibration';
        dims = [1 50];
        definput = {'100'};
        answer = inputdlg(prompt,dlgtitle,dims,definput);
        
        mmLineLength = eval(answer{1});
        
        delete(cropLine)
        delete(text1)
        obj.calibration.pxSize = pxLineLength/mmLineLength;
        
    elseif strcmp(calibrationmethod,'dye') == 1 && nargin == 2
        % TODO: dye calibration function under development
        
        error('Dye calibration functionalities currently under development.')
        
    elseif strcmp(calibrationmethod,'checker') == 1 && nargin >= 3 && nargin <= 4
        
        % dialog box start calibration
        answer = questdlg('Start checkerboard calibration?','Yes', 'No');
        switch answer
            case 'Yes'
                fprintf('\nStarting calibration...\n')
                
                % create calibration* folder ------------------
                dirOutputsCalib = dir('outputs/calibration*');
                calibNumber = numel(dirOutputsCalib);
                expName = ['calibration' num2str(calibNumber+1)];
                mkdir(['outputs/' expName]);
                addpath(['outputs/' expName])
                
                % acquire 10 images for calibration -----------
                if nargin == 4
                    numCalibrationImages = numcalibrationimages;
                else
                    numCalibrationImages = 10;
                end
                for i = 1:numCalibrationImages
                    set(obj.liveStream.Parent.Parent,'color',[0.95 0.95 0.95])
                    textImg = text(0,-200,['\bf{Image #' num2str(i) '/ ' num2str(numCalibrationImages) '}']);
                    for j = 1:4
                        textAq = text(0,-100,['Acquiring image in ' num2str(4-j)]);
                        pause(1)
                        drawnow
                        delete(textAq)
                    end
                    calibrationImage = getsnapshot(obj.camera.vid);
                    set(obj.liveStream.Parent.Parent,'color','w')
                    textAq = text(0,-100,'Acquired.');
                    drawnow
                    pause(1)
                    delete(textImg)
                    delete(textAq)
                    imwrite(calibrationImage,['outputs/' expName '/calibrationImage' num2str(i) '.tif'])
                end
                set(obj.liveStream.Parent.Parent,'color',[0.9 0.9 0.9])
                
                % evaluate calibration from images ------------
                fprintf('\nEvaluating calibration...\n')
                
                % define images to process
                imageDirectory = dir(['outputs/' expName '/calibrationImage*.tif']);
                imageNumber = numel(imageDirectory);
                for i = 1:imageNumber
                    imageFileName = imageDirectory(i).name;
                    imageFileNames{i} = imageFileName;
                end
                
                % detect checkerboards in images
                fprintf('\nDetecting checkerboard points...\n')
                [imagePoints, boardSize, imagesUsed] = detectCheckerboardPoints(imageFileNames);
                imageFileNames = imageFileNames(imagesUsed);
                
                % read the first image to obtain image size
                originalImage = imread(imageFileNames{1});
                [mrows, ncols, ~] = size(originalImage);
                
                % generate world coordinates of the corners of the squares
                worldPoints = generateCheckerboardPoints(boardSize, squaresize);
                
                % calibrate the camera
                fprintf('\nEstimating camera parameters...\n')
                [cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
                    'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
                    'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'millimeters', ...
                    'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', [], ...
                    'ImageSize', [mrows, ncols]);
                
                % view reprojection errors
                reprojectionErrors=figure; showReprojectionErrors(cameraParams);
                
                % visualize pattern locations
                patternLocation=figure; showExtrinsics(cameraParams, 'CameraCentric');
                
                % display parameter estimation errors
                displayErrors(estimationErrors, cameraParams);
                
                % estimate pixel size on first measurement
                px1 = imagePoints(1,1,1);
                py1 = imagePoints(1,2,1);
                px2 = imagePoints(2,1,1);
                py2 = imagePoints(2,2,1);
                squareSizeInPx = sqrt( (px1-px2)^2 + (py1-py2)^2 );
                pxsize = squaresize/squareSizeInPx;
                
                % save calibration in obj.calibration
                fprintf('\nSaving camera parameters...\n')
                obj.calibration.pxSize = pxsize;
                obj.calibration.imageFileNames = imageFileNames;
                obj.calibration.imagePoints = imagePoints;
                obj.calibration.boardSize = boardSize;
                obj.calibration.imagesUsed = imagesUsed;
                obj.calibration.originalImage = originalImage;
                obj.calibration.mrows = mrows;
                obj.calibration.ncols = ncols;
                obj.calibration.worldPoints = worldPoints;
                obj.calibration.cameraParams = cameraParams;
                obj.calibration.estimationErrors = estimationErrors;
                obj.calibration.reprojectionErrors = reprojectionErrors;
                obj.calibration.patternLocation = patternLocation;
                fprintf('\nCalibration complete.\n')
                
            case 'No'
                fprintf('\nCalibration cancelled.\n')
        end
    else
        error('Wrong number of inputs.')
    end
    
else
    error('Wrong number of inputs')
end


end