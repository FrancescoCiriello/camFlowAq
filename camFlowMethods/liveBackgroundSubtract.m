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
