function camLivestream(obj,process)

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
    set(obj.camera.vid,'FramesperTrigger',1,'TriggerRepeat',Inf);    % stores 1 frame at a time
    warning('off','images:imshow:magnificationMustBeFitForDockedFigure')
            try
                start(obj.camera.vid);
                while islogging(obj.camera.vid) == 1
                    frame = getdata(obj.camera.vid,1);
                    flushdata(obj.camera.vid)
                    switch process
                    
                        case 0 % no processing
                            processedFrame=frame;
                            
                        case 1 % background subtraction
                            if isempty(obj.background) == 1
                                error('No background image acquired.')  % TODO: acquire background
                            end
                            processedFrame = imsubtract(im2double(frame),obj.background.frame);
                            
                        case 2 % sobel edge detection
                            processedFrame = rgb2gray(frame);
                            [~,threshold] = edge(processedFrame,'sobel');
                            fudgeFactor = 0.5;
                            processedFrame=edge(processedFrame,'sobel',threshold * fudgeFactor);
                        
                        case 3 % face tracking
                            faceDetector = vision.CascadeObjectDetector();
                            frame = rgb2gray(frame);
                            bbox = step(faceDetector, frame);
                            processedFrame = insertObjectAnnotation(frame,'rectangle',bbox,'Eejit');
                    end
                    obj.liveStream = imshow(processedFrame);
                    drawnow
                end
            catch
                if ishandle(obj.liveStream) == 1
                    close(obj.liveStream.Parent.Parent)
                end
                stop(obj.camera.vid);
                fprintf('\nLive background close.\n')
                
                % reset preview status
                obj.previewStatus = 0;
                obj.advancedPreviewStatus = 0;
            end
            
            % reset preview status
            obj.previewStatus = 1;
            obj.advancedPreviewStatus = 0;
end