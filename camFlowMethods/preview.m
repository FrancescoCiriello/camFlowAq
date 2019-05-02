function preview(obj)
% use preview to open a figure docked to the working
% environment that previews the videoinput from the camera
%
% See also PREVIEW, CROP.

% TODO: find a way to reset preview status when figure closed
% manually

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