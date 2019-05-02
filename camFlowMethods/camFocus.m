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