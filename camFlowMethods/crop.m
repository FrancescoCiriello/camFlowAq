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