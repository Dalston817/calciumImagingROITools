% Showing various visualizations that can be done with .mat data
% Just uncomment a section to try it out. Uses mat file in Example data
% folder.
% Be sure to only have one section uncommented at a time.
% David Alston January-2021 (david.alston@louisville.edu)
% NOTES:
%{
    - When trying to pull data out of the cellData struct, you can use tab
    to autocomplete. So type cellData(1).After_Drift then hit tab, you will
    see all data from after drift correction. You can click any of these
    and it will auto fill the correct name.
%}
clc
close all
clear
addpath(genpath('Functions'));
%% Loading mat data
addpath(genpath('Example data'));
load('827_2.mat'); % Can also just drag this .mat file onto the workspace on the right in Matlab.
cellData = dataStruct.ROIdata; % Pull out just cell/stim specific data to make easier to use
stimData = dataStruct.stimTable; % As above but for stimulus/baseline frame #'s
%% Generate simple plot of after drift main-background with stimulus start/end shown
%{
cellNum = 1; % Which cell to look at
dF_F = cellData(cellNum).After_Drift_MBDIFF_dF_F; % Drift corrected (main - background) dF_F
stimStarts = stimData{:, 1}; % Stimulus starts (frame number)
stimEnds = stimData{:, 2};
figure
plot(dF_F);
hold on
for N = 1:size(stimStarts, 1)
    xline(stimStarts(N), 'm', 'LineWidth', 1); % Draw start frame in magenta for current stim
    xline(stimEnds(N), 'g', 'LineWidth', 1);   % Draw end frame in green for current stim
end
hold off
title('Drift corrected Main-background dFF');
xlabel('Frame number');
%}
%% As above, but highlight regions rather than just drawing boundary lines
cellNum = 1; % Which cell to look at
dF_F = cellData(cellNum).After_Drift_MBDIFF_dF_F; % Drift corrected (main - background) dF_F
stimStarts = stimData{:, 1}; % Stimulus starts (frame number)
stimEnds = stimData{:, 2};
figure
plot(dF_F);
hold on
yl = ylim;
for N = 1:size(stimStarts, 1) % For each stimulus
    startS = stimStarts(N);
    endS = stimEnds(N);
    x = [startS endS endS startS];
    y = [yl(1) yl(1) yl(2) yl(2)]; % Highlight entire Y-range of figure
    patch(x, y, 'green', 'FaceAlpha', 0.1); % Change FaceAlpha for transparency control
end
hold off
title('Drift corrected Main-background dFF');
xlabel('Frame number');
%% Generate a % of points significant based on standard deviation of baseline and plot
%{
% Note does not look at absolute value of dF_F, can be easily added in thresh check
baselineStdMult = 0.1; % Multiplier to standard deviation of background used in threshold
cellNum = 1; % Which cell to look at
stimNum = 3; % Which stimulus to look at
%dF_F = cellData(cellNum).After_Drift_MBDIFF_dF_F; % Drift corrected (main - background) dF_F
dF_F = cellData(cellNum).After_Drift_M_dF_F; % Drift corrected main dF_F
stimStart = stimData{stimNum, 1}; % Stimulus start (frame number)
stimEnd = stimData{stimNum, 2};
baselineStd = cellData(cellNum).After_Drift_B_baseStd(stimNum, 1);
thresh = baselineStdMult*baselineStd;
for N = 1:(stimEnd-stimStart)
    currPt = dF_F(stimStart+N-1, 1);
    if currPt > thresh
        dF_F(stimStart+N-1, 2) = 1;
        
    else
        dF_F(stimStart+N-1, 2) = 0;
    end
end
if sum(dF_F(:, 2)) == 0
    fprintf('No points significantly above threshold set for cell %i and stimulus %i\n', cellNum, stimNum);
else
    sigPercent = 100*(sum(dF_F(:, 2))/size(dF_F, 1));
    fprintf('Some points were significantly above threshold. Percentage = %f\n', sigPercent);
    plot(dF_F(:, 1));
    yl = ylim;
    x = [stimStart stimEnd stimEnd stimStart];
    y = [yl(1) yl(1) yl(2) yl(2)];
    patch(x, y, 'green', 'FaceAlpha', 0.1); % Change FaceAlpha for transparency control    
    title('Drift corrected Main-background dFF with significant points and stimuli range');
    xlabel('Frame number'); 
    sigIdx = find(dF_F(:, 2));
    hold on   
    for S = 1:size(sigIdx, 1)
        x = sigIdx(S, 1);
        y = dF_F(x, 1);
        plot(x, y, 'o', 'MarkerEdgeColor', 'magenta');
    end
    hold off
end
%}