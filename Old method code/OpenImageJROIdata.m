%%this script reads data from ImageJ ROI manager table and calculates dF_F
%%the output is dF_F, found in the Workspace to the right-->


%%measure ROIs in ImageJ and save in ROI Manager.  
%%"Measure all" and save results to file.

%%while still in ImageJ, run the plugin "Read and Write Excel"
%%this will save your ROI manager table to an .xlsx file on the DESKTOP

%%then run the script below.  It will open the desktop and ask for the file
%%Files saved by "Read and Write Excel" are neamed "Rename me after writing is done.xlsx" 

clc; clear;
[FileName,PathName] = uigetfile('*.xlsx','Select the xlsx file','C:\Users\sroper\Desktop');
path=strcat(PathName,FileName);
data = readtable(path);
Roi_num=width(data);

% note, Matlab opens Excel into a TABLE format.  The following line
% converts this Table into an array for subsequent processing:

data=table2array(data);
prompt = 'how many scans is your baseline? ';
q = input(prompt);

%%from here, I copied script from Erika (Liberles lab)

[framenum cellnum] = size(data);
%[nothing stimnum] = size(stimuli);

master = [];

% for each cell...
for i = 1:1:cellnum
    
% get statistics for whole trace

fbase = mean(data(1:q,:));

%calculate df/F

normcell = (data(:,i) - fbase(i))/ fbase(i);

master = [master normcell];
end

%%note that the first column of the array is still the cell number ID.
%thus, to calculate dF/Fo, you perform the operation only on columns 2 to
%the end:

dF_F=(master(:,2:end));

%%you can now use this file dF_F in the other Roper lab scripts