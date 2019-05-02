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
    obj.format = validatestring(action,validActions);
    
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