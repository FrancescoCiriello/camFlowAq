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