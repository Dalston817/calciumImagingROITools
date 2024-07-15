function [myStruct] = ROIs2MaskStruct_F(roiStruct, refImg)
%{
% ROIs2MaskStruct_F
% 
% PURPOSE: Convert an roi struct created by the ImageJ ROI manager
% into a Matlab struct format.
% 
% INPUTS: 
%   - roiStruct = ROI cell array as read by ReadImageJROI.m
%   - refImg = A single frame from the image stack. Used to define width/height.
% 
% OUTPUTS: 
%   - myStruct = A Matlab struct with # of ROI rows containing:
%       -- .mask = binary mask of ROI
%       -- .type = 'M' or 'B' for main or background
%       -- .ID = Positive integer. So 1M would have ID = 1 etc
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2020b but may work
% 	on earlier versions). Should not require any toolboxes.
% 
% AUTHOR: David C Alston (david.alston@louisville.edu) 2021.
% 
% NOTES:
%   - Adapted from a section of NewNoDrift_PART_A.m by by S Roper
%   - Supported types are Oval, Polygon, Freehand, and FreeLine
%   - Assumes ROIs are named as '1M', '1B', '95M', '95B', etc.
%}
[numRows, numCols] = size(refImg);
myStruct(1, size(roiStruct, 2)) = struct();
myStruct(1).mask = false(size(refImg));
myStruct(1).type = 'INIT';
myStruct(1).ID = -1;
for N = 1:size(roiStruct, 2)
    currRoi = roiStruct{N};
    switch currRoi.strType
        case 'Oval'
            xc = 1/2*(currRoi.vnRectBounds(2)+currRoi.vnRectBounds(4));
            yc = 1/2*(currRoi.vnRectBounds(1)+currRoi.vnRectBounds(3));
            a = 1/2*(currRoi.vnRectBounds(4)-currRoi.vnRectBounds(2));
            b = 1/2*(currRoi.vnRectBounds(3)-currRoi.vnRectBounds(1));
            alfa = linspace(0,360,1024).*(pi/180); % use 1024 points to draw the ellipse
            xi = xc+a.*cos(alfa);  % get points on the ellipse
            yi = yc+b.*sin(alfa);
            roiMask = poly2mask(xi, yi, numRows, numCols);
        case 'Polygon'
            xi = [currRoi.mnCoordinates(:,1); currRoi.mnCoordinates(1,1)];
            yi = [currRoi.mnCoordinates(:,2); currRoi.mnCoordinates(1,2)];
            roiMask = poly2mask(xi, yi, numRows, numCols);
        case 'Freehand'
            xi = [currRoi.mnCoordinates(:,1); currRoi.mnCoordinates(1,1)];
            yi = [currRoi.mnCoordinates(:,2); currRoi.mnCoordinates(1,2)];
            roiMask = poly2mask(xi, yi, numRows, numCols);
        case 'FreeLine'
            xi = [currRoi.mnCoordinates(:,1); currRoi.mnCoordinates(1,1)];
            yi = [currRoi.mnCoordinates(:,2); currRoi.mnCoordinates(1,2)];
            roiMask = poly2mask(xi, yi, numRows, numCols);
        otherwise
            beep;
            disp('roi2Mask_F ERROR:: ROI is not a supported tpype (Oval, Polygon, or Freehand).');
            fprintf('Type was: %s\n', currRoi.strType);
            roiMask = -1;
    end
    myStruct(N).mask = roiMask;
    myStruct(N).type = currRoi.strName(end); % 'M' or 'B'
    myStruct(N).name = currRoi.strName;
    myStruct(N).ID = str2double(currRoi.strName(1:end-1));
end