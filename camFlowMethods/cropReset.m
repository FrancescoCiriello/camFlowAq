function cropReset(obj)
% use cropReset to reset FOV to original camera resolution
res = obj.camera.vid.VideoResolution;
obj.camera.vid.ROIPosition = [0 0 res(1) res(2)];
end