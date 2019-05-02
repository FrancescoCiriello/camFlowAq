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