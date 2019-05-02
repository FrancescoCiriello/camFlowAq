%% The camFlowAq class provides a toolbox for using the JAI cameras.
% A video acquisition object is created using this class.
%
% Simply calling camFlowAq creates an object with default settings.
%
% Calling camFlowAq(interface,devicenumber,format) can be used to specify which
% camera input and which bit depth mode to use.
% 
% List of properties (defaults shown):
% - deviceNumber
% - format = 'Mono8';
% - interface = 'gentl'
% - infoSys (stores Matlab info)
% - info (stores camera information)
% - numCamerasFound
% - camera property contains vid (videoinput object) and src (source) files
% - liveStream (figure handle on videoinput object)
% - previewStatus (is camera previewing?)
% - advancedPreviewStatus (is camera previewing in advanced mode?)
% - background
% - calibration
% 
% Camera settings can be accessed (and accordingly modified) in obj.camera.src
% Preview these with
% get(obj.camLoad.src)
%
% List of methods
% - load: loads video stream from camera into the object
% - preview: previews video into a docked figure
% - crop: choose an ROI
% - acquire: start the acquisition via a dialog box
%
% Developed by F. Ciriello & Nicholas H. Wise for G. R. Hunt's  Fluids Lab at CUED (May 2019)

classdef camFlowAq < handle    % attributed a handle superclass
    properties
        numCamerasFound
        deviceNumber
        format
        interface
        infoSys
        info
        camera
        liveStream
        liveStreamFigure
        previewStatus
        advancedPreviewStatus
        background
        calibration
        stereoCalibration
    end
    methods
        % constructor class
        function obj = camFlowAq(interface,devicenumber,format) 
            
            % read system info
            obj.infoSys = imaqhwinfo;
            
            % check installed hardware adaptors
            validInterfaces = obj.infoSys.InstalledAdaptors;
            obj.interface = validatestring(interface,validInterfaces);
            
            % read selected interface info
            obj.info = imaqhwinfo(obj.interface);
            obj.numCamerasFound = numel(obj.info.DeviceIDs);
            
            if isempty(obj.info.DeviceIDs) == 1
               error('No cameras connected.')  
            end
            
            % check supported Format
            validFormats = obj.info.DeviceInfo.SupportedFormats;
            if nargin == 3
                obj.format = validatestring(format,validFormats);
            end
            
            % initialise preview status
            obj.previewStatus = 0;
            obj.advancedPreviewStatus = 0;
            
            % load a camera ----------------------------------------------
            if  nargin == 1
                obj.deviceNumber = 1;
                obj.format = validFormats(1);   % first format in list is default
            elseif nargin == 2 || nargin == 3
                if devicenumber <= obj.numCamerasFound
                    obj.deviceNumber = devicenumber;
                else
                    error('Camera ID not found')
                end
                
                if nargin == 2
                    obj.format = validFormats(1);   % first format in list is default
                elseif nargin == 3
                    obj.format = cellstr(format);
                end
            else
                error('Wrong number of input arguments')
            end


            % Directories -------------------------------------------------
            % check if outputs folder exists and if it does not make it
            if exist([cd, '/outputs'],'file') == 0
                mkdir('outputs')
                mkdir('outputs/temp')
            else
                addpath('outputs')
                addpath('outputs/temp')
            end
            
            % check if cameraSettings folder exists and if it does not, make a
            % folder in current directory
            if exist([cd, '/cameraSettings'],'file') == 0
                mkdir('cameraSettings')
            else
                addpath('cameraSettings')
            end
            
            % Load camera videoinput---------------------------------------
            % Use camera to load the videoinput into the videoJaiAq object
            obj.camera.vid = videoinput(obj.interface, obj.deviceNumber, string(obj.format(1)));
            obj.camera.src = getselectedsource(obj.camera.vid);
            
            % impose default settings for the camera mode so that they are
            % in manual mode
            if strcmp(interface,'gentl')
                obj.camera.src.ExposureMode = 'Timed';
            elseif strcmp(interface,'winvideo')
                obj.camera.src.ExposureMode = 'manual';
                obj.camera.src.WhiteBalanceMode = 'manual';
            end
            
            % set default docked for the livestream figure objects
            set(0,'DefaultFigureWindowStyle','docked')
            
            % print device name
            fprintf('Camera %s loaded.\n', obj.info.DeviceInfo(obj.deviceNumber).DeviceName);
        end
    end
    
end
