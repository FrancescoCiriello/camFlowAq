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

% single-camera acquisition -----------------------------------------------
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
        % TODO: known bug - saving from temp folder does not work
        if nargin >=2
            validBackgroundSaveStatus = ["on","off",""];
            validatestring(savebackground,validBackgroundSaveStatus);
            if strcmp(savebackground,'on') == 1
                if isempty(obj.background) == 1
                    error('No background video found')
                else
                    fprintf('\nSaving background from temp folder...\n')
                    copyfile('outputs/temp/background.avi',['outputs/' expName '/background.avi'],'f')
                    imwrite(obj.background.frame,['outputs/' expName '/background.tif'])
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
    
% TODO: multi-camera acquisition --------------------------------------
else
    fprintf('\nMulti-camera acquisition under development.\n')
end


end