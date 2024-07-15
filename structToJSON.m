clc
close all
clear
addpath(genpath('Functions'));
%% Example showing how to export struct data as a JSON file (if don't want to use Matlab)
% Writes '827_2_asJSON.json' to the code folder
addpath(genpath('Example data'));
load('827_2.mat'); % Can also just drag this .mat file onto the workspace on the right in Matlab.
% Struct called 'dataStruct'
encodedStruct = jsonencode(dataStruct, PrettyPrint=true);
fid = fopen('827_2_asJSON.json', 'w');
try
    fprintf(fid, '%s', encodedStruct);
catch
    beep;
    disp("JSON write error. Closing file");
    fclose(fid);
end
fclose(fid);
