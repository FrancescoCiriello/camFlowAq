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