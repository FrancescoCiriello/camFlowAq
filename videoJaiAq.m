%% The videoJaiAq class provides a toolbox for using the JAI cameras.
% A video acquisition object is created using this class.
%
% Simply calling videoJaiAq creates an object with default settings.
%
% Calling videoJaiAq(devicenumber,bitdepth) can be used to specify which
% camera input and which bit depth mode to use.
% 
% List of properties (defaults shown):
% - deviceNumber
% - bitDepth = 'Mono8';
% - interface = 'gentl'
% - info (stores camera information)
% - numCamerasFound
% - camera property contains vid (videoinput object) and src (source) files
% - liveStream (figure handle on videoinput object)
% - previewStatus (is camera previewing?)
% - advancedPreviewStatus (is camera previewing in advanced mode?)
% - background
% - calibration
% 
% Camera settings can be accessed (and accordingly modified) in obj.camera.src
% Preview these with
% get(obj.camLoad.src)
%
% List of methods
% - load: loads video stream from camera into the object
% - preview: previews video into a docked figure
% - crop: choose an ROI
% - acquire: start the acquisition via a dialog box
%
% Developed by F. Ciriello for G. R. Hunt's  Fluids Lab at CUED (April 2019)

classdef videoJaiAq < handle    % attributed a handle superclass
    properties
        numCamerasFound
        deviceNumber
        bitDepth
        interface;
        info
        camera
        liveStream
        liveStreamFigure
        previewStatus
        advancedPreviewStatus
        background
        calibration
        stereoCalibration
%         info = imaqhwinfo('gentl')'
    end
    methods
        % constructor class
        function obj = videoJaiAq(interface,devicenumber,settings) 
            
            validInterfaces = ["gentl","winvideo"];
            obj.interface = validatestring(interface,validInterfaces);
            
            obj.info = imaqhwinfo(obj.interface);
            obj.numCamerasFound = numel(obj.info.DeviceIDs);
            
            if obj.numCamerasFound == 0
               error('No cameras connected.')   % TODO fix this
            end
            
            % load a GenICam
            if strcmp(interface,'gentl') == 1
                
                if  nargin == 0
                    obj.deviceNumber = 1;
                    obj.bitDepth = 'Mono8';
                elseif nargin == 2 || nargin == 3
                    if devicenumber <= obj.numCamerasFound
                        obj.deviceNumber = devicenumber;
                    else
                        error('Camera ID not found')
                    end
                    validBitDepths = ["Mono8","Mono10","Mono12"];
                    obj.bitDepth = validatestring(settings,validBitDepths);
                else
                    error('Wrong number of input arguments')
                end
                obj.previewStatus = 0;
                obj.advancedPreviewStatus = 0;
                
                % load a webCam
            elseif strcmp(interface,'winvideo')
                if  nargin == 0 % no device number specified
                    obj.deviceNumber = 1; % default input first camera if present
                    obj.bitDepth = 'MJPG_1280x720'; % default bitDepth
                elseif nargin == 2 || nargin == 3 % if device number specified
                    if devicenumber <= obj.numCamerasFound % check whether device number exists
                        obj.deviceNumber = devicenumber; 
                    else
                        error('Camera ID not found')   % if not, output error
                    end
                    
                    % check string array for valid bitdepths
                    validBitDepths = ["MJPG_1280x720","MJPG_848x480","MJPG_960x540"];
                    obj.bitDepth = validatestring(settings,validBitDepths);
                else
                    error('Wrong number of input arguments')
                end
                obj.previewStatus = 0;
                obj.advancedPreviewStatus = 0;
            end
            
            % check if outputs folder exists and if it does not make it
            if exist([cd, '/outputs'],'file') == 0
                mkdir('outputs')
                mkdir('outputs/temp')
            else
                addpath('outputs')
                addpath('outputs/temp')
            end
            
            % check if cameraSettings folder exists and if it does not, make a
            % folder in current directory
            if exist([cd, '/cameraSettings'],'file') == 0
                mkdir('cameraSettings')
            else
                addpath('cameraSettings')
            end
            
            % Use camera to load the videoinput into the videoJaiAq object
            obj.camera.vid = videoinput(obj.interface, obj.deviceNumber, obj.bitDepth);
            obj.camera.src = getselectedsource(obj.camera.vid);
            
            % impose default settings for the camera mode so that they are
            % in manual mode
            if strcmp(interface,'gentl')
                obj.camera.src.ExposureMode = 'Timed';
            elseif strcmp(interface,'winvideo')
                obj.camera.src.ExposureMode = 'manual';
                obj.camera.src.WhiteBalanceMode = 'manual';
            end
            
            % set up figure object
            set(0,'DefaultFigureWindowStyle','docked')
            
            % print device name
            fprintf('Camera %s loaded.\n', obj.info.DeviceInfo(devicenumber).DeviceName);
        end
        
        
        function camSettings(obj,action,filename)
            % the camSettings function opens a dialog box for choosing camera
            % settings. The second argument can be used to 'save' or 'load'
            % settings in the cameraSettings folder. NOTE: the 'save' and
            % 'load' functionalities still not working.
            
            % settings for the GenICam
            if strcmp(obj.interface,'gentl') == 1
                if nargin == 1
                    % opens up larger settings dialog box
                    prompt = {'Number of frames:','Acquisition fps:','Exposure fps:', 'Digital Gain:'};
                    dlgtitle = ['Camera settings for ', obj.info.DeviceInfo.DeviceName];
                    dims = [1 100];
                    definput = {num2str(obj.camera.vid.FramesPerTrigger) ,num2str(obj.camera.src.AcquisitionFrameRate),num2str(10^6/obj.camera.src.ExposureTime),num2str(obj.camera.src.Gain)};
                    answer = inputdlg(prompt,dlgtitle,dims,definput);
                    
                    obj.camera.vid.FramesPerTrigger = eval(answer{1});
                    obj.camera.src.AcquisitionFrameRate = eval(answer{2});
                    if eval(answer{3}) == eval(answer{2}) && obj.previewStatus == 0 %% % TODO figure out how to check whether preview is on
                        obj.camera.src.ExposureMode = 'Off';
                    else
                        obj.camera.src.ExposureTime = min(10^6/eval(answer{3}) , 10^6/eval(answer{2}));    % n.b. camera input is in micro seconds
                    end
                    obj.camera.src.Gain = eval(answer{4});
                end
                
                % settings for the webCam
            elseif strcmp(obj.interface,'winvideo') == 1
                 if nargin == 1  % not saving or loading
                    % opens up larger settings dialog box
                    prompt = {'Digital Gain:','Gamma','Brightness','White Balance','Exposure'};
                    dlgtitle = ['Camera settings for ', obj.info.DeviceInfo.DeviceName];
                    dims = [1 100];
                    definput = {num2str(obj.camera.src.Gain), num2str(obj.camera.src.Gamma),num2str(obj.camera.src.Brightness),num2str(obj.camera.src.WhiteBalance),num2str(obj.camera.src.Exposure)};
                    answer = inputdlg(prompt,dlgtitle,dims,definput);
                    
                    obj.camera.src.Gain = eval(answer{1});
                    obj.camera.src.Gamma = eval(answer{2});
                    obj.camera.src.Brightness = eval(answer{3});
                    obj.camera.src.WhiteBalance = eval(answer{4});
                    obj.camera.src.Exposure = eval(answer{5});
                    
  
                end
            end
            
            if nargin == 2 || nargin == 3
                validActions = ["save","load"];
                obj.bitDepth = validatestring(action,validActions);
                
                if nargin == 2  
                    dirOutputsCamSettings = dir('cameraSettings/settings.*.mat');
                    settingsNumber = numel(dirOutputsCamSettings);
                    filename = ['settings.' num2str(settingsNumber+1)];
                end
                    
                if strcmp(action,'save') == 1
                    settings = obj.camera.src;
                    save(['cameraSettings/' filename '.mat'],'settings')
                elseif strcmp(action,'load') == 1  %% TODO: load settings load as structure and not as object
                    settings = load(['cameraSettings/' filename '.mat'],'settings');
%                     settings = struct2class(videosource,s);
                    obj.camera.src = settings;
                end
                
            elseif nargin > 3
                error('Wrong number of inputs')
            end
            
            function object = struct2class(classname, s)
                % converts structure s to an object of class classname.
                % assumes classname has a constructor which takes no arguments
                object = eval(classname);  %create object
                for fn = fieldnames(s)'    %enumerat fields
                    try
                        object.(fn{1}) = s.(fn{1});   %and copy
                    catch
                        warning('Could not copy field %s', fn{1});
                    end
                end
            end
            
        end
        
        % preview methods
        function preview(obj)
            % use preview to open a figure docked to the working
            % environment that previews the videoinput from the camera
            % 
            % See also PREVIEW, CROP.
            
            numCams = length(obj);
           
            
            % single camera preview
            if numCams == 1
                % close previews if these are already open
                if obj.advancedPreviewStatus == 1
                    close(obj.liveStream.Parent.Parent);
                end
                
                % set up preview figure
                res = obj.camera.vid.VideoResolution;
                obj.liveStream = image(zeros(res(2),res(1)));
                set(gcf,'Visible','on')    % required to run in a live script
                set(gca,'visible','off')
                axis equal tight
                preview(obj.camera.vid, obj.liveStream);
                
                % reset preview status
                obj.previewStatus = 1;
                obj.advancedPreviewStatus = 0;
            
            % multicamera preview
            elseif numCams > 1
                if ishandle(obj(1).liveStream) == 1 
                    close(obj(1).liveStream.Parent.Parent);
                end
                
                % preview multicamera mode
                for k = 1:numCams
                    subplot(2,ceil(numCams/2),k)
                    res = obj(k).camera.vid.VideoResolution;
                    obj(k).liveStream = image(zeros(res(2),res(1)));
                    set(gcf,'Visible','on')    % required to run in a live script
                    set(gca,'visible','off')
                    axis equal tight
                    preview(obj(k).camera.vid, obj(k).liveStream);
                    % reset preview status
                    obj(k).previewStatus = 1;
                    obj(k).advancedPreviewStatus = 0;
                end

            end
                  
        end
        
        function advancedPreview(obj)
            % use advancedPreview to open a figure docked to the working
            % environment that previews the videoinput from the camera
            % the advanced features allow you to inspect the live video
            % histogram of pixel intensities
            %
            %
            % See also PREVIEW, CROP.
                       
            % preview video stream
            set(gcf,'Visible','on')    % required to output figure while using a live script
            subplot(2,2,[1 2])
            set(gca,'visible','off')
            res = obj.camera.vid.VideoResolution;
            obj.liveStream = image(zeros(res(2),res(1)));
            preview(obj.camera.vid, obj.liveStream);
            axis equal tight
            
            % live histogram of pixel intensities + pie chart
            warning('off','MATLAB:pie:NonPositiveData')
            setappdata(obj.liveStream,'UpdatePreviewWindowFcn',@liveHist);
            
            function liveHist(object,event,fighandle)
                set(fighandle, 'CData', event.Data);
                
                % histogram
                subplot(2,2,3);
                imhist(event.Data, 128);
                drawnow
                
                % pie chart of saturation
                subplot(2,2,4);
                black = sum(sum(event.Data >= 0 &  event.Data < 10));
                grey = sum(sum(event.Data >= 10 & event.Data < 250));
                white = sum(sum(event.Data >= 250 & event.Data <= 255));
                pie([black + 1, grey + 1, white + 1])
                text(-0.6,-1.6,'\bf{grey levels}')
                drawnow     

            end
            obj.previewStatus = 0;
            obj.advancedPreviewStatus = 1;
        end
        
        % preview tools
        function cropReset(obj)
            % use cropReset to reset FOV to original camera resolution
            res = obj.camera.vid.VideoResolution;
            obj.camera.vid.ROIPosition = [0 0 res(1) res(2)];      
        end
        
        function camColor(obj,colormap)
            % use camColor to change the color scheme in the live stream
            % figure
            % the second argument is the colormap
            
            if nargin == 2
                if strcmp(colormap,'satColor') == 1
                    colormap = gray(255);
                    colormap(1:10,:) = [1 0 0].*ones(10,3);
                    colormap(end-9:end,:) = [0 1 0].*ones(10,3);
                end
                if obj.previewStatus == 1 || obj.advancedPreviewStatus == 1
                    obj.liveStream.Parent.Colormap = colormap;
                else
                    error('Live stream not open')
                end
            else
                error('No colormap choosen.')
            end

        end
        
        function crop(obj)
            % use crop to preview the image and choose the ROI for the
            % camera. A user-input is required in the figure to draw out
            % the rectangle for the ROI. The rectangle can be adjusted as
            % many times as needed after the first selection by dragging on the nodes.
            % Double-click to confirm the ROI selection.
            %
            % See also IMRECT, PREVIEW.
            
            % if all previews are closed - open default preview and ask for crop
            if obj.advancedPreviewStatus == 0 && obj.previewStatus == 0
                fprintf('\nDefault preview mode loaded.\n')
                set(gcf,'Visible','on')    % required to run in a live script
                set(gca,'visible','off')
                res = obj.camera.vid.VideoResolution;
                obj.liveStream = image(zeros(res(2),res(1)));
                preview(obj.camera.vid, obj.liveStream);
                axis equal tight
                
                % user-input for crop rectangle
                text1 = text(0,-100,'Adjust ROI and double-click to confirm crop');
                cropRectangle = imrect(gca);
                pos = wait(cropRectangle);
                obj.camera.vid.ROIPosition = floor(pos);
                delete(cropRectangle) 
                delete(text1)
                clear pos
                text2 = text(0,-100,'Cropping done');
                pause(3)
                delete(text2)
                
            % if preview is already open - then start crop
            elseif  obj.advancedPreviewStatus == 0 && obj.previewStatus == 1
                % user-input for crop rectangle
                text1 = text(0,-100,'Adjust ROI and double click-to confirm crop');
                cropRectangle = imrect(gca);
                pos = wait(cropRectangle);
                obj.camera.vid.ROIPosition = floor(pos);
                delete(cropRectangle)
                delete(text1)
                clear pos
                text2 = text(0,-100,'Cropping done');
                pause(3)
                delete(text2)
                
            % if advancedpreview is already open - then start crop
            elseif  obj.advancedPreviewStatus == 1 && obj.previewStatus == 0
                subplot(2,2,[1 2])
                text1 = text(0,-100,'Adjust ROI and double click-to confirm crop');
                cropRectangle = imrect(gca);
                pos = wait(cropRectangle);
                obj.camera.vid.ROIPosition = floor(pos);
                delete(cropRectangle)
                delete(text1)
                clear pos
                text2 = text(0,-100,'Cropping done');
                pause(3)
                delete(text2)
                
            end
        end
        
        function camFocus(obj)
            % The camFocus functions provides capabilities to assist in the
            % cameras manual focus. The obj.focusStream figure handle opens
            % on the user-input of a zoomed-in ROI. Image of the zoom and
            % array of pixels intensities displayed. The more detail in the
            % signal the better the focus.
            
            % open live stream  -------------------------------------------
            
            % if all previews are closed - open default preview and ask for
            % focus ROI
            
                fprintf('\nDefault preview mode loaded.\n')
                set(gcf,'Visible','on')    % required to run in a live script
                set(gca,'visible','off')
                res = obj.camera.vid.VideoResolution;
                obj.liveStream = image(zeros(res(2),res(1)));
                preview(obj.camera.vid, obj.liveStream);
                axis equal tight
                
                
                % user-input for crop rectangle
                text1 = text(0,-100,'Choose Zoom ROI and double-click to confirm');
                focusRectangle = imrect(gca);
                pos = wait(focusRectangle);
                sizeFocusROI = floor([pos(3) - pos(1), pos(4) - pos(2)]);
                obj.camera.vid.ROIPosition = floor(pos);
                delete(focusRectangle) 
                delete(text1)
                
                % display live stream of cropped ROI
                subplot(2,2,[1 2])
                obj.liveStream = image(zeros(res(2),res(1)));
                preview(obj.camera.vid, obj.liveStream);
                axis equal tight
                
                % display live pixels intensity arrays of the ROI
                warning('off','MATLAB:colon:nonIntegerIndex')
                setappdata(obj.liveStream,'UpdatePreviewWindowFcn',@livePixArray);
                
                % create a button to quit focus tool
                
                panel = uipanel(obj.liveStream.Parent.Parent,'Position',[0.03 0.03 0.22 0.08]);
                control = uicontrol(panel,'Style','pushbutton');
                control.String = 'Focus complete';
                control.Callback = @button;
                
            function button(source,event)
                close all
            end
            function livePixArray(object,event,fighandle)
                set(fighandle, 'CData', event.Data);
                
                lx = size(event.Data,1);
                ly = size(event.Data,2);
                vpixarray = event.Data(:,end/4:end/4:3*end/4);
                hpixarray = event.Data(end/4:end/4:3*end/4,:)';
                
                subplot(2,2,3);
                plot(hpixarray)
                ylim([0 255])
                title('Horizontal pixels')
                drawnow
                

                subplot(2,2,4);
                plot(vpixarray)
                ylim([0 255])
                title('Vertical pixels')
                drawnow
            end
  
        end
        
        % calibration
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
        
        % acquisition
        function acquire(obj, savebackground, savecalibration, framenumber, moviename, liveaq)
            % use acquire to start the acquisition of the video.
            %
            % Optional 2nd argument can be used to save currently temp held
            % background in the exp* folder - takes 'on' or 'off'
            %
            % Optional 3rd argument can be used to specify number of frames to
            % acquire
            %
            % Optional 4th argument can be used to specify the filename for the
            % movie. Movies are saved in the 'outputs/exp*' directory. There is in-built
            % safety functionalities to avoid overwritting movies.
            %
            % Optional 5th argument can be used to set the live acquisition
            % mode 'on' or 'off'
            
            % single-camera acquisition
            if length(obj) == 1
                
                % TODO: live acquisition functionalities do not work 
                % set default mode to live acquisition if no argument is
                % specified
                if exist('liveaq','var') == 0
                    liveaq = 'on';
                else
                    % error handle for incorrect argument 4
                    validLiveAqStates = ["on","off",""];
                    validatestring(liveaq,validLiveAqStates);
                end
                
                % check if live acquisition has already been triggered
                
                
                % if live acquisition mode is turned off then close all figures
                % and reset preview status
                if strcmp(liveaq,'off') == 1
                    % close live acquisition if mode set to off
                    fprintf('\nLive acquisition mode turned off.\n')
                    if ishandle(obj.liveStream) == 1
                        close(obj.liveStream.Parent.Parent);
                        obj.previewStatus = 0;
                        obj.advancedPreviewStatus = 0;
                    end
                    
                elseif obj.previewStatus == 0 && obj.advancedPreviewStatus == 0
                    fprintf('\nOpening livestream...\n')
                    % open figure
                    set(gcf,'Visible','on')    % required to run in a live script
                    set(gca,'visible','off')
                    res = obj.camera.vid.VideoResolution;
                    obj.liveStream = image(zeros(res(2),res(1)));
                    preview(obj.camera.vid, obj.liveStream);
                    axis equal tight
                    
                    % if in advancedPreview, switch to normal preview to avoid
                    % conflict with dialog boxes and figure callbacks
                elseif obj.advancedPreviewStatus == 1
                    fprintf('\nQuitting advanced preview mode.\n')
                    close(obj.liveStream.Parent.Parent);
                    fprintf('\nOpening livestream...\n')
                    set(gcf,'Visible','on')    % required to run in a live script
                    set(gca,'visible','off')
                    res = obj.camera.vid.VideoResolution;
                    obj.liveStream = image(zeros(res(2),res(1)));
                    preview(obj.camera.vid, obj.liveStream);
                    axis equal tight
                    obj.previewStatus = 1;
                    obj.advancedPreviewStatus = 0;
                    
                end
                
                
                
                % create movie ------------------------------------------------
                
                % if no movie name given > movies are called 'raw' and placed
                % in exp* folder
                if  nargin >= 1
                    dirOutputsMov = dir('outputs/exp*');
                    movNumber = numel(dirOutputsMov);
                    if movNumber == 0
                        expName = ['exp' num2str(movNumber+1,'%0.3d')];
                    else
                        lastExpNum = eval(erase(dirOutputsMov(end).name,'exp'));
                        expName = ['exp' num2str(lastExpNum + 1,'%0.3d')];
                    end
                    mkdir(['outputs/' expName]);
                    addpath(['outputs/' expName])
                    
                    % save as raw
                    if nargin < 5
                        % monochrome videos
                        if strcmp(obj.interface,'gentl')
                            diskLogger = VideoWriter(['outputs/' expName '/raw'], 'Grayscale AVI');
                            fps = obj.camera.src.AcquisitionFrameRate;
                        % color videos
                        elseif strcmp(obj.interface,'winvideo')  
                            diskLogger = VideoWriter(['outputs/' expName '/raw'], 'Uncompressed AVI');
                            fps = eval(obj.camera.src.FrameRate);
                        end
                        obj.camera.vid.LoggingMode = 'disk';
                        obj.camera.vid.DiskLogger = diskLogger;
                        
                        diskLogger.FrameRate =  fps;
                        fprintf('\nCreating movie ''raw.avi'' in %s folder.\n', expName)
                    end
                    
                    
                    % save background from temp folder if prompted
                    if nargin >=2
                        validBackgroundSaveStatus = ["on","off",""];
                        validatestring(savebackground,validBackgroundSaveStatus);
                        if strcmp(savebackground,'on') == 1
                            if isempty(obj.background) == 1
                                error('No background video found')
                            else
                                fprintf('\nSaving background from temp folder...\n')
                                video = obj.background.video;
                                frame = obj.background.frame;
                                save(['outputs/' expName '/background.avi'],'video')
                                save(['outputs/' expName '/background.tif'],'frame')
                            end
                        else
                            fprintf('\nAcquiring without background image.\n')
                        end
                    end
                    
                    % save calibration if prompted
                    if nargin >=3
                        validCalibrationSaveStatus = ["on","off",""];
                        validatestring(savecalibration,validCalibrationSaveStatus);
                        if strcmp(savecalibration,'on') == 1
                            if isempty(obj.calibration) == 1
                                error('No calibration found')
                            else
                                fprintf('\nSaving calibration...\n')
                                calibration = obj.calibration;
                                save(['outputs/' expName '/calibration.mat'],'calibration')

                            end
                        else
                            fprintf('\nAcquiring without calibration.\n')
                        end
                    end
                    
                    % reset frame number to user-defined input
                    if nargin >= 4
                        if isnumeric(framenumber) == 1
                            obj.camera.vid.FramesPerTrigger = framenumber;
                        else
                        end
                    end
                    
                    
                    % use given moviename
                    if nargin >= 5
                        % save to disk
                        
                        % monochrome
                        if strcmp(obj.interface,'gentl')
                            diskLogger = VideoWriter(['outputs/' expName, '/' moviename], 'Grayscale AVI');
                             fps = obj.camera.src.AcquisitionFrameRate;
                        % coloured
                        elseif strcmp(obj.interface,'winvideo')
                            diskLogger = VideoWriter(['outputs/' expName, '/' moviename], 'Uncompressed AVI');
                             fps = eval(obj.camera.src.FrameRate);
                        end
                        obj.camera.vid.LoggingMode = 'disk';
                        obj.camera.vid.DiskLogger = diskLogger;
                        diskLogger.FrameRate =  fps;
                        fprintf('\nCreating movie ''%s'' in %s folder.\n', moviename, expName)
                    end
                    
                elseif nargin > 6 || nargin == 0
                    error('Wrong number of input arguments')
                end
                
                % acquire images - manual trigger required to start acquisition
                % after camera has loaded
                triggerconfig(obj.camera.vid, 'manual');
                start(obj.camera.vid);
                
                % dialog box to start acquisition - islogging used to display
                % camera is acquiring
                answer = questdlg('Acquire video?','Yes', 'No');
                switch answer
                    case 'Yes'
                        trigger(obj.camera.vid)
                        fprintf('\nAcquiring images...\n')
                        while islogging(obj.camera.vid) == 1
                            
                        end
                        fprintf('\nImage acquisition complete\n')
                    case 'No'
                        fprintf('\nImage acquisition cancelled.\n')
                end
                
                % TODO: multi-camera acquisition
            else
                fprintf('\nMulti-camera acquisition under development.\n')
            end
            
            
        end
        
        function acquireBackground(obj,numberofframes)
            
            if length(obj) == 1
                
                % if in advanced preview mode go to default preview mode
                if ishandle(obj.liveStream) == 1 && obj.advancedPreviewStatus == 1
                    close(obj.liveStream.Parent.Parent);
                    obj.advancedPreviewStatus = 0;
                    set(gcf,'Visible','on')    % required to run in a live script
                    set(gca,'visible','off')
                    res = obj.camera.vid.VideoResolution;
                    obj.liveStream = image(zeros(res(2),res(1)));
                    preview(obj.camera.vid, obj.liveStream);
                    axis equal tight
                    obj.previewStatus = 1;
                end
                
                
                obj.background.name = 'background';
                
                % momentarily store number of acquisition frames
                numAqFramesStore = obj.camera.vid.FramesPerTrigger;
                
                % set number of background frames to acquire
                if nargin == 1
                    numberofframes = 100;
                    obj.camera.vid.FramesPerTrigger = numberofframes;
                elseif nargin == 2
                    obj.camera.vid.FramesPerTrigger = numberofframes+1;
                else
                    error('Wrong number of inputs')
                end
                
                % set up background video save
                diskLogger = VideoWriter(['outputs/temp/' obj.background.name ], 'Grayscale AVI');
                obj.camera.vid.LoggingMode = 'disk';
                obj.camera.vid.DiskLogger = diskLogger;
                diskLogger.FrameRate =  obj.camera.src.AcquisitionFrameRate;
                fprintf('\nCreating temporary background file...\n')
                
                % acquire background images
                triggerconfig(obj.camera.vid, 'manual');
                start(obj.camera.vid);
                trigger(obj.camera.vid)
                fprintf('\nAcquiring background images...\n')
                while islogging(obj.camera.vid) == 1
                end
                fprintf('\nBackground video acquisition complete\n')
                
                % get background video
                pause(1)
                path = getfield(obj.camera.vid.Disklogger,'Path');
                obj.background.video = VideoReader([path, '\background.avi']);
                v = VideoReader([path, '\background.avi']); % required to use read as dot notation not supported
                
                % create average background
                pos = obj.camera.vid.ROIPosition;
                res = [pos(3), pos(4)];
                
                % initialise
                fprintf('\nCreating background image...\n')
                frameSum = zeros(res(2),res(1));
                for i = 2 : numberofframes
                    currentFrame = read(v, i);
                    frameSum = frameSum  + im2double(currentFrame);
                end
                obj.background.frame = frameSum / numberofframes;
                clear v
                fprintf('\nBackground image created.\n')
                
                % restore number of acquisition frames to pre-selected
                obj.camera.vid.FramesPerTrigger = numAqFramesStore;
                
            % TODO: multi-camera background acquisition
            else
                fprintf('\nMulti-camera background acquisition under development.\n')
                
                
            end
        end
        
        % live image processing
        function liveBackgroundSubtract(obj)
            % the liveBackgroundSubtract displays a live stream of a
            % background subtracted video. 
            
            % This is the simplest structure for performing operation on a
            % live video stream
            
            % check whether background exists
            if isempty(obj.background) == 1
                error('No background image acquired.')  % TODO: acquire background
            end
            
            % close advanced preview if open
            if obj.advancedPreviewStatus == 1
                close(obj.liveStream.Parent.Parent);
            end
            
            % create figure object for live stream (obj.liveStream)
            res = obj.camera.vid.VideoResolution;
            obj.liveStream = image(zeros(res(2),res(1)));
            set(gcf,'Visible','on')    % required to run in a live script
            set(gca,'visible','off')
            axis equal tight
            
            % start acquisition 
            obj.camera.vid.LoggingMode = 'memory';
            triggerconfig(obj.camera.vid, 'immediate');
            set(obj.camera.vid,'FramesperTrigger',10,'TriggerRepeat',Inf);    % stores 10 frames at a time
            warning('off','images:imshow:magnificationMustBeFitForDockedFigure')
            try
                start(obj.camera.vid);
                while islogging(obj.camera.vid) == 1
                    frame = getdata(obj.camera.vid,1);
                    flushdata(obj.camera.vid)
                    processedFrame = imsubtract(im2double(frame),obj.background.frame);
                    obj.liveStream = imshow(processedFrame);
                    drawnow
                end
            catch
                if ishandle(obj.liveStream) == 1
                    close(obj.liveStream.Parent.Parent)
                end
                stop(obj.camera.vid);
                fprintf('\nLive background close.\n')
            end
            
            % reset preview status
            obj.previewStatus = 1;
            obj.advancedPreviewStatus = 0;
        end
    end
end
