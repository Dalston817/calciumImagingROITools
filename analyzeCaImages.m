%{
% analyzeCaImages.m
% 
% PURPOSE: Read a TIF image stack and do ROI processing for main/background
% 
% INPUTS: See CONTROLS section
% 
% OUTPUTS: .mat file and .excel file with processed data
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2021a but may work
% 	on earlier versions). Also:
%   - Image processing toolbox.
%   - ReadImageJROI.m
%   - ROIs2MaskStruct_F.m
% 
% AUTHOR: David C Alston (david.alston@louisville.edu) June 2021.
% 
% NOTES:
%   - Must have an even number of ROI's in your ROI zip file (one main and
%       one background per cell).
%
%   - Up to 252 cells supported for writing to excel (since writes one
%       sheet per cell). This can be changed if that limit becomes an issue.
%       = raw dF_F sheet + drift corr dF_F sheet + INFO sheet + up to 252 cell sheets = excel max = 255
%}
clc
close all
clear
addpath(genpath('Functions'));
%% CONTROLS
driftFactor = 1.25;  % See line 196 onward in NewNoDrift_PART_A.m. 1.25 to 3 suggested
genFigures = 0;      % 0 = don't generate figures, 1 = generate figures
%% USER PROMPTS FOR FILES
[file, path] = uigetfile('*.tif', 'Select registered .tif stack');
if file == 0; return; end % Handle user canceling prompt
tifFile = fullfile(path, file);
justName = extractBefore(file, '.');
ROIsFile = fullfile(path, strcat(justName, '.zip'));
stimFile = fullfile(path, strcat(justName, '.xlsx'));
figFolder = fullfile(path, 'Figures');
if genFigures
    if exist(figFolder, 'file') == 0; mkdir(figFolder); end % Returns 7 if folder already exists
end
%% MAIN PROGRAM START
disp('Reading TIF and converting ROIs to binary masks...');
stimTable = readtable(stimFile);
numStim = size(stimTable, 1);
if mod(size(stimTable, 2), 2) ~= 0
    beep;
    disp('ERROR:: Odd number of columns in stimulus sheet. Check the excel file. Closing...');
    return
end
refImg = im2double(imread(tifFile, 1));
origTIFStack = zeros(size(refImg, 1), size(refImg, 2), numel(imfinfo(tifFile)));
for N = 1:numel(imfinfo(tifFile)); origTIFStack(:, :, N) = im2double(imread(tifFile, N)); end
[roiStruct] = ROIs2MaskStruct_F(ReadImageJROI(ROIsFile), refImg);
refMean = mean(origTIFStack, 3);
disp('Done');
%% PER ROI PROCESSING
if mod(size(roiStruct, 2), 2) ~= 0
    beep;
    disp('ERROR:: Odd number of ROIs. Check you have an M and B for each ROI. Closing...');
    return
end
IDsTODO = unique([roiStruct.ID].');
dataStruct.stimTable = stimTable;
dataStruct.driftFactor = driftFactor;
dataStruct.processedDate = datetime;
loadBar = waitbar(0, '0', 'Name', 'Processing ROIs...');
numCells = ((size(roiStruct, 2))/2); % A main ROI and a background ROI is one loop iteration
disp('Doing per-ROI processing...');
for R = 1:numCells
    %% Grab M and B structs for current ID
    currID = IDsTODO(R, 1);
    IDs = [roiStruct.ID];
    IDX = find(IDs == currID); % Should only be two IDX here
    struct1 = roiStruct(IDX(1));
    if strcmp(struct1.type, 'M')
        mStruct = roiStruct(IDX(1));
        bStruct = roiStruct(IDX(2));
    else
        mStruct = roiStruct(IDX(2));
        bStruct = roiStruct(IDX(1));
    end
    if ~strcmp(mStruct.type, 'M') || ~strcmp(bStruct.type, 'B') % If naming is not correct error out
        beep;
        disp('ERROR:: Error finding ROIs in zip file. Check ROI naming is of the form 1M, 1B, 2M, 2B, etc. Closing... ');
        return        
    end
    %% get dF_F for main and background for the entire stack (under the masks)
    mIDX = find(mStruct.mask); % Linear indicies of main mask
    bIDX = find(bStruct.mask);
    mdF = zeros(size(origTIFStack, 3), 1); % dF from New_No_Drift part A but for main (M)
    bdF = mdF; % dF from New_No_Drift part A but for background (B)
    for S = 1:size(origTIFStack, 3)
        currFrame = origTIFStack(:, :, S);
        mdF(S, 1) = mean(currFrame(mIDX));
        bdF(S, 1) = mean(currFrame(bIDX));
    end
    mF0 = mean(mdF(1:9, 1));
    bF0 = mean(bdF(1:9, 1));
    mdF_F = (mdF - mF0)./mF0;
    bdF_F = (bdF - bF0)./bF0;
    % Need to check smoothing is correct given the array layout NewNoDrift uses:
    %{
    for i=1:size(mdF_F, 1)
        mdF_F2 = smooth(mdF_F(i,:), 3);
        bdF_F2 = smooth(bdF_F(i,:), 3);
        mdF_F(i,:) = mdF_F2;
        bdF_F(i,:) = bdF_F2;
    end
    %}
    %% Remove first numBaseline points in baseline (if > mean of b + 2*stdev)
    % Calculated again for excel sheet in later loop (baseline mean + std)
    for S = 1:numStim
        baseStart = stimTable{S, 3};
        baseEnd = stimTable{S, 4};
        if (baseEnd - baseStart) < 1
            beep;
            fprintf('ERROR:: Baseline width was < 1 for stimulus # %i\n', S);
            return
        end
        mfbase = mean(mdF_F(baseStart:baseEnd));
        mfstdev = std(mdF_F(baseStart:baseEnd));
        bfbase = mean(bdF_F(baseStart:baseEnd));
        bfstdev = std(bdF_F(baseStart:baseEnd));
        mThresh = mfbase + 2*mfstdev;
        bThresh = bfbase + 2*bfstdev;
        mClipdata = mdF_F; % So don't modify original mdF_F
        bClipdata = bdF_F;
        for Q = baseStart:baseEnd
            if mClipdata(Q) > mThresh; mClipdata(Q) = mfbase; end
            if bClipdata(Q) > bThresh; bClipdata(Q) = bfbase; end
        end
        mdF_F = mClipdata; % Updates mdF_F with corrected portion (read again next loop in mClipdata = mdF_F)
        bdF_F = bClipdata;
    end
    %% Drift correction (last step before plotting etc.)    
    mFactor = driftFactor*std(mdF_F(1:30));
    bFactor = driftFactor*std(bdF_F(1:30));
    mNoDrift = zeros(numel(imfinfo(tifFile)), 1);
    bNoDrift = mNoDrift;
    mNoDrift(1:20, 1) = mdF_F(1:20, 1);  % Rather than first c loop
    bNoDrift(1:20, 1) = bdF_F(1:20, 1);
    for c = 21:numel(imfinfo(tifFile))-1 % Fill in rest after 20
        mCurrPt = mdF_F(c, 1);
        bCurrPt = bdF_F(c, 1);
        mPrevPt = mdF_F(c-1, 1);
        bPrevPt = bdF_F(c-1, 1);
        
        mPrevNoDrift = mNoDrift(c-1, 1);
        bPrevNoDrift = bNoDrift(c-1, 1);
        
        mabs1 = abs(mCurrPt - mPrevPt);
        mabs2 = abs(mCurrPt - mPrevNoDrift);
        
        babs1 = abs(bCurrPt - bPrevPt);
        babs2 = abs(bCurrPt - bPrevNoDrift);
        if mabs1 > mFactor || mabs2 > mFactor
            mNoDrift(c, 1) = mean(mNoDrift((c-4):(c-1), 1));            
        else
            mNoDrift(c, 1) = mdF_F(c, 1);
        end
        
        if babs1 > bFactor || babs2 > bFactor
           bNoDrift(c, 1) = mean(bNoDrift((c-4):(c-1), 1));            
        else
           bNoDrift(c, 1) = bdF_F(c, 1);
        end
    end
    mMovAvg = movmean(mNoDrift, 10);
    bMovAvg = movmean(bNoDrift, 10);   
    mDriftCorr = mdF_F - mMovAvg;
    bDriftCorr = bdF_F - bMovAvg;    
    %% Calculate AUC, max, and max diff for all stimuli    
    for S = 1:numStim
        startStim = stimTable{S, 1};
        endStim = stimTable{S, 2};        
        baseStart = stimTable{S, 3};
        baseEnd = stimTable{S, 4};
        
        mPreDrift = mdF_F(startStim:endStim);             % Main dF_F, pre drift
        mBasePreDrift = mdF_F(baseStart:baseEnd);         % Main baseline, pre drift        
        bPreDrift = bdF_F(startStim:endStim);             % Background dF_F, pre drift        
        bBasePreDrift = bdF_F(baseStart:baseEnd);         % Background baseline, pre drift   
        mbPreDrift = mPreDrift - bPreDrift;               % Main minus background dF_F, pre drift
        mbBasePreDrift = mBasePreDrift - bBasePreDrift;   % Main minus background baseline, pre drift
        
        mPostDrift = mDriftCorr(startStim:endStim);       % Main dF_F, post drift
        mBasePostDrift = mDriftCorr(baseStart:baseEnd);   % Main baseline, post drift
        bPostDrift = bDriftCorr(startStim:endStim);       % Background dF_F, post drift
        bBasePostDrift = bDriftCorr(baseStart:baseEnd);   % Background baseline, post drift
        mbPostDrift = mPostDrift - bPostDrift;            % Main minus background dF_F, post drift
        mbBasePostDrift = mBasePostDrift - bBasePostDrift;% Main minus background baseline, post drift        
        %% AUC, max, max diff, mean, and STD pre drift (Main and background seperately)
        mAUCPreDrift(S, 1) = trapz(mPreDrift); %#ok<SAGROW>
        bAUCPreDrift(S, 1) = trapz(bPreDrift); %#ok<SAGROW>
        mMaxPreDrift(S, 1) = max(mPreDrift); %#ok<SAGROW>
        bMaxPreDrift(S, 1) = max(bPreDrift); %#ok<SAGROW>
        [~, mIDX] =  max(abs(diff(mPreDrift)));
        [~, bIDX] = max(abs(diff(bPreDrift)));
        mMaxDiffPreDrift(S, 1) = mPreDrift(mIDX); %#ok<SAGROW>
        bMaxDiffPreDrift(S, 1) = bPreDrift(bIDX); %#ok<SAGROW>
        mBaseMeanPreDrift(S, 1) = mean(mBasePreDrift);%#ok<SAGROW>
        bBaseMeanPreDrift(S, 1) = mean(bBasePreDrift);%#ok<SAGROW>
        mBaseSTDPreDrift(S, 1) = std(mBasePreDrift);%#ok<SAGROW>
        bBaseSTDPreDrift(S, 1) = std(bBasePreDrift);%#ok<SAGROW>
        %% AUC, max, max diff, mean, and STD post drift (Main and background seperately)
        mAUCPostDrift(S, 1) = trapz(mPostDrift); %#ok<SAGROW>
        bAUCPostDrift(S, 1) = trapz(bPostDrift); %#ok<SAGROW>
        mMaxPostDrift(S, 1) = max(mPostDrift); %#ok<SAGROW>
        bMaxPostDrift(S, 1) = max(bPostDrift); %#ok<SAGROW>
        [~, mIDX] =  max(abs(diff(mPostDrift)));
        [~, bIDX] = max(abs(diff(bPostDrift)));
        mMaxDiffPostDrift(S, 1) = mPostDrift(mIDX); %#ok<SAGROW>
        bMaxDiffPostDrift(S, 1) = bPostDrift(bIDX); %#ok<SAGROW>
        mBaseMeanPostDrift(S, 1) = mean(mBasePostDrift);%#ok<SAGROW>
        bBaseMeanPostDrift(S, 1) = mean(bBasePostDrift);%#ok<SAGROW>
        mBaseSTDPostDrift(S, 1) = std(mBasePostDrift);%#ok<SAGROW>
        bBaseSTDPostDrift(S, 1) = std(bBasePostDrift);%#ok<SAGROW>
        %% AUX, max, max diff, mean, and STD pre drift (Main minus background)
        mbAUCPreDrift(S, 1) = trapz(mbPreDrift); %#ok<SAGROW>
        mbMaxPreDrift(S, 1) = max(mbPreDrift); %#ok<SAGROW>
        [~, mbIDX] = max(abs(diff(mbPreDrift)));
        mbMaxDiffPreDrift(S, 1) = mbPreDrift(mbIDX); %#ok<SAGROW>
        mbBaseMeanPreDrift(S, 1) = mean(mbBasePreDrift);%#ok<SAGROW>
        mbBaseSTDPreDrift(S, 1) = std(mbBasePreDrift); %#ok<SAGROW>
        %% AUX, max, max diff, mean, and STD post drift (Main minus background)
        mbAUCPostDrift(S, 1) = trapz(mbPostDrift); %#ok<SAGROW>
        mbMaxPostDrift(S, 1) = max(mbPostDrift); %#ok<SAGROW>
        [~, mbIDX] = max(abs(diff(mbPostDrift)));
        mbMaxDiffPostDrift(S, 1) = mbPostDrift(mbIDX); %#ok<SAGROW>  
        mbBaseMeanPostDrift(S, 1) = mean(mbBasePostDrift);%#ok<SAGROW>
        mbBaseSTDPostDrift(S, 1) = std(mbBasePostDrift);%#ok<SAGROW>
    end
    dataStruct.ROIdata(R).MainName = mStruct.name;
    dataStruct.ROIdata(R).BackgroundName = bStruct.name;
    %% Pre drift main and background data    
    dataStruct.ROIdata(R).Before_Drift_M_dF_F = mdF_F;
    dataStruct.ROIdata(R).Before_Drift_B_dF_F = bdF_F;
    dataStruct.ROIdata(R).Before_Drift_M_AUC = mAUCPreDrift;
    dataStruct.ROIdata(R).Before_Drift_B_AUC = bAUCPreDrift;
    dataStruct.ROIdata(R).Before_Drift_M_Max = mMaxPreDrift;
    dataStruct.ROIdata(R).Before_Drift_B_Max = bMaxPreDrift;    
    dataStruct.ROIdata(R).Before_Drift_M_diffMax = mMaxDiffPreDrift;
    dataStruct.ROIdata(R).Before_Drift_B_diffMax = bMaxDiffPreDrift;
    dataStruct.ROIdata(R).Before_Drift_M_baseMean = mBaseMeanPreDrift;
    dataStruct.ROIdata(R).Before_Drift_B_baseMean = bBaseMeanPreDrift;
    dataStruct.ROIdata(R).Before_Drift_M_baseStd = mBaseSTDPreDrift;
    dataStruct.ROIdata(R).Before_Drift_B_baseStd = bBaseSTDPreDrift;
    %% Post drift main and background data
    dataStruct.ROIdata(R).After_Drift_M_dF_F = mDriftCorr;    
    dataStruct.ROIdata(R).After_Drift_B_dF_F = bDriftCorr;
    dataStruct.ROIdata(R).After_Drift_M_AUC = mAUCPostDrift;
    dataStruct.ROIdata(R).After_Drift_B_AUC = bAUCPostDrift;
    dataStruct.ROIdata(R).After_Drift_M_Max = mMaxPostDrift;
    dataStruct.ROIdata(R).After_Drift_B_Max = bMaxPostDrift;    
    dataStruct.ROIdata(R).After_Drift_M_diffMax = mMaxDiffPostDrift;
    dataStruct.ROIdata(R).After_Drift_B_diffMax = bMaxDiffPostDrift;    
    dataStruct.ROIdata(R).After_Drift_M_baseMean = mBaseMeanPostDrift;
    dataStruct.ROIdata(R).After_Drift_B_baseMean = bBaseMeanPostDrift;
    dataStruct.ROIdata(R).After_Drift_M_baseStd = mBaseSTDPostDrift;
    dataStruct.ROIdata(R).After_Drift_B_baseStd = bBaseSTDPostDrift;
    %% Pre drift main-background data
    dataStruct.ROIdata(R).Before_Drift_MBDIFF_dF_F = mdF_F - bdF_F;
    dataStruct.ROIdata(R).Before_Drift_MBDIFF_AUC = mbAUCPreDrift;
    dataStruct.ROIdata(R).Before_Drift_MBDIFF_Max = mbMaxPreDrift;
    dataStruct.ROIdata(R).Before_Drift_MBDIFF_diffMax = mbMaxDiffPreDrift;
    dataStruct.ROIdata(R).Before_Drift_MBDIFF_baseMean = mbBaseMeanPreDrift;
    dataStruct.ROIdata(R).Before_Drift_MBDIFF_baseStd = mbBaseSTDPreDrift;
    %% Post drift main-background data
    dataStruct.ROIdata(R).After_Drift_MBDIFF_dF_F = mDriftCorr - bDriftCorr;
    dataStruct.ROIdata(R).After_Drift_MBDIFF_AUC = mbAUCPostDrift;
    dataStruct.ROIdata(R).After_Drift_MBDIFF_Max = mbMaxPostDrift;
    dataStruct.ROIdata(R).After_Drift_MBDIFF_diffMax = mbMaxDiffPostDrift;
    dataStruct.ROIdata(R).After_Drift_MBDIFF_baseMean = mbBaseMeanPostDrift;
    dataStruct.ROIdata(R).After_Drift_MBDIFF_baseStd = mbBaseSTDPostDrift;
    loadStr = strcat(int2str(R), '/', int2str(numCells));
    waitbar(R/numCells, loadBar, loadStr);
end
close(loadBar);
disp('Done'); 
clearvars -except dataStruct tifFile numCells numStim figFolder genFigures
%% Write data to excel and .mat from created struct (up to 252 cells supported for excel export)
disp('Data formatted into struct. Writing to .mat...');
matName = strcat(strtok(tifFile, '.'), '.mat');
save(matName, 'dataStruct'); % This writes data to .mat
driftFactor = dataStruct.driftFactor;
stimTable = dataStruct.stimTable;
procDate = dataStruct.processedDate;
roiData = dataStruct.ROIdata;
excelName = strcat(strtok(tifFile, '.'), '-XLS.xlsx');
disp('Done');
%% Write matlab figures to figFolder (before and after drift main, background, and main-background dF_F. Six figures per cell)
if genFigures
    disp('Finished writing mat data. Writing matlab figures to Figures folder...'); %#ok<*UNRCH>
    loadBar = waitbar(0, '0', 'Name', 'Writing figures to .fig files...');
    driftStr = num2str(driftFactor);
    for R = 1:size(roiData, 2)
        fldrName = strcat('Cell-', num2str(R));
        toWriteFldr = fullfile(figFolder, fldrName);
        if exist(toWriteFldr, 'file') == 0; mkdir(toWriteFldr); end % Returns 7 if folder already exists
        BD_B_dF_F = dataStruct.ROIdata(R).Before_Drift_B_dF_F;
        BD_M_dF_F = dataStruct.ROIdata(R).Before_Drift_M_dF_F;
        BD_MB_dF_F = dataStruct.ROIdata(R).Before_Drift_MBDIFF_dF_F; % Main - background
        AD_B_dF_F = dataStruct.ROIdata(R).After_Drift_B_dF_F;
        AD_M_dF_F = dataStruct.ROIdata(R).After_Drift_M_dF_F;
        AD_MB_dF_F = dataStruct.ROIdata(R).After_Drift_MBDIFF_dF_F; % Main - background
        % Set up titles and file names
        BD_B_dF_F_Title = strcat(fldrName, '-Before Drift-Background-dFF'); % No _ in dFF since title() interprets that as subscript
        BD_B_dF_F_Name =  fullfile(toWriteFldr, strcat(fldrName, '-BD-Background dF_F'));
        BD_M_dF_F_Title = strcat(fldrName, '-Before Drift-Main-dFF');
        BD_M_dF_F_Name =  fullfile(toWriteFldr, strcat(fldrName, '-BD-Main dF_F'));
        BD_MB_dF_F_Title = strcat(fldrName, '-Before Drift-Main minus Background-dFF');
        BD_MB_dF_F_Name =  fullfile(toWriteFldr, strcat(fldrName, '-BD-Main minus Background dF_F'));
        AD_B_dF_F_Title = strcat(fldrName, '-After Drift-Background-dFF-driftCorr-', driftStr);
        AD_B_dF_F_Name =  fullfile(toWriteFldr, strcat(fldrName, '-AD-Background dF_F'));
        AD_M_dF_F_Title = strcat(fldrName, '-After Drift-Main-dFF-driftCorr-', driftStr);
        AD_M_dF_F_Name =  fullfile(toWriteFldr, strcat(fldrName, '-AD-Main dF_F'));
        AD_MB_dF_F_Title = strcat(fldrName, '-After Drift-Main minus Background-dFF-driftCorr-', driftStr);
        AD_MB_dF_F_Name =  fullfile(toWriteFldr, strcat(fldrName, '-AD-Main minus Background dF_F'));
        % Create figures and write to file (.fig) - Before drift background
        myF = figure;
        plot(BD_B_dF_F);
        title(BD_B_dF_F_Title);
        savefig(myF, BD_B_dF_F_Name);
        close(myF);
        % Before drift main
        myF = figure;
        plot(BD_M_dF_F);
        title(BD_M_dF_F_Title);
        savefig(myF, BD_M_dF_F_Name);
        close(myF);
        % Before drift main - background
        myF = figure;
        plot(BD_MB_dF_F);
        title(BD_MB_dF_F_Title);
        savefig(myF, BD_MB_dF_F_Name);
        close(myF);
        % After drift background
        myF = figure;
        plot(AD_B_dF_F);
        title(AD_B_dF_F_Title);
        savefig(myF, AD_B_dF_F_Name);
        close(myF);
        % After drift main
        myF = figure;
        plot(AD_M_dF_F);
        title(AD_M_dF_F_Title);
        savefig(myF, AD_M_dF_F_Name);
        close(myF);
        % After drift main - background
        myF = figure;
        plot(AD_MB_dF_F);
        title(AD_MB_dF_F_Title);
        savefig(myF, AD_MB_dF_F_Name);
        close(myF);
        loadStr = strcat(int2str(R), '/', num2str(size(roiData, 2)));
        waitbar(R/size(roiData, 2), loadBar, loadStr);
    end
    close(loadBar);
    disp('Done');   
end
%% Write pre-drift correction sheet (Main and background AUC, max, and dF_F for each cell/stimuli)
disp('Writing excel data...');
rawSheetName = 'raw dF_F'; % Sheet name
writecell({tifFile}, excelName, 'Sheet', rawSheetName, 'Range', 'A1'); % TIF filename to cell A1
Cell = zeros(numCells, 1);
AUC_B = zeros(numCells, numStim); %Not including blank column to be added manually
MAX_B = zeros(numCells, numStim);
STDBASE_B = zeros(numCells, numStim);
AUC_M = zeros(numCells, numStim);
MAX_M = zeros(numCells, numStim);
STDBASE_M = zeros(numCells, numStim);
AUC_MB = zeros(numCells, numStim);
MAX_MB = zeros(numCells, numStim);
STDBASE_MB = zeros(numCells, numStim);
for C = 1:numCells
    currCellStruct = dataStruct.ROIdata(C);
    Cell(C, 1) = C;  
    dF_F_M(C, :) = currCellStruct.Before_Drift_M_dF_F'; %#ok<SAGROW>
    dF_F_B(C, :) = currCellStruct.Before_Drift_B_dF_F'; %#ok<SAGROW>
    dF_F_MB(C, :) = currCellStruct.Before_Drift_MBDIFF_dF_F; %#ok<SAGROW> Main - background      
    AUC_M(C, :) = currCellStruct.Before_Drift_M_AUC'; % 5-13-21 bugfix, wrote wrong data
    AUC_B(C, :) = currCellStruct.Before_Drift_B_AUC';
    AUC_MB(C, :) = currCellStruct.Before_Drift_MBDIFF_AUC';   
    MAX_M(C, :) = currCellStruct.Before_Drift_M_Max';
    MAX_B(C, :) = currCellStruct.Before_Drift_B_Max';
    MAX_MB(C, :) = currCellStruct.Before_Drift_MBDIFF_Max';    
    STDBASE_M(C, :) = currCellStruct.Before_Drift_M_baseStd';
    STDBASE_B(C, :) = currCellStruct.Before_Drift_B_baseStd';
    STDBASE_MB(C, :) = currCellStruct.Before_Drift_MBDIFF_baseStd';
end
eT1 = array2table(NaN(numCells, 1)); % writetable() should convert nan to empty array (eT = empty table)
eT1.Properties.VariableNames = {'Blank1'}; % Can't have duplicate names in table. So need blank1, blank2, etc
eT2 = array2table(NaN(numCells, 1));
eT2.Properties.VariableNames = {'Blank2'}; 
eT3 = array2table(NaN(numCells, 1));
eT3.Properties.VariableNames = {'Blank3'};
eT4 = array2table(NaN(numCells, 1));
eT4.Properties.VariableNames = {'Blank4'}; 
eT5 = array2table(NaN(numCells, 1)); 
eT5.Properties.VariableNames = {'Blank5'};
eT6 = array2table(NaN(numCells, 1)); 
eT6.Properties.VariableNames = {'Blank6'};
eT7 = array2table(NaN(numCells, 1));
eT7.Properties.VariableNames = {'Blank7'};
eT8 = array2table(NaN(numCells, 1));
eT8.Properties.VariableNames = {'Blank8'};
eT9 = array2table(NaN(numCells, 1));
eT9.Properties.VariableNames = {'Blank9'};
eT10 = array2table(NaN(numCells, 1));
eT10.Properties.VariableNames = {'Blank10'}; 
eT11 = array2table(NaN(numCells, 1));
eT11.Properties.VariableNames = {'Blank11'}; 
cellT = array2table(Cell);

dffM = array2table(dF_F_M);
dffB = array2table(dF_F_B);
dffMB = array2table(dF_F_MB); % Main - background

aucMT = array2table(AUC_M);
aucBT = array2table(AUC_B);
aucMBT = array2table(AUC_MB);

maxMT = array2table(MAX_M);
maxBT = array2table(MAX_B);
maxMBT = array2table(MAX_MB);

stdBaseMT = array2table(STDBASE_M);
stdBaseBT = array2table(STDBASE_B);
stdBaseMBT = array2table(STDBASE_MB);
% Writing each as background, main, then main-background for each variable
T1 = horzcat(cellT, aucBT, eT1, aucMT, eT2, aucMBT, eT3); % Cell and AUC portions
T2 = horzcat(maxBT, eT4, maxMT, eT5, maxMBT, eT6); % Max
T3 = horzcat(stdBaseBT, eT7, stdBaseMT, eT8, stdBaseMBT, eT9); % STDBASE
T4 = horzcat(dffB, eT10, dffM, eT11, dffMB); % dF_F
finTable = horzcat(T1, T2, T3, T4);
%finTable = horzcat(cellT, aucBT, eT1, aucMT, eT2, maxBT, eT3, maxMT, eT4, stdBaseBT, eT5, stdBaseMT, eT6, dffB, eT7, dffM, eT8, dffMB);
writetable(finTable, excelName, 'Sheet', rawSheetName, 'Range', 'B4');
%% Write drift corrected sheet (Main and background AUC, max, and dF_F for each cell/stimuli)
driftSheetName = 'drift-corrected dF_F';
writecell({tifFile}, excelName, 'Sheet', driftSheetName, 'Range', 'A1');     % TIF filename to cell A1
writecell({driftFactor}, excelName, 'Sheet', driftSheetName, 'Range', 'A2'); % Drift correction factor to A2
AUC_B = zeros(numCells, numStim); %Not including blank column to be added manually
MAX_B = zeros(numCells, numStim);
STDBASE_B = zeros(numCells, numStim);
AUC_M = zeros(numCells, numStim);
MAX_M = zeros(numCells, numStim);
STDBASE_M = zeros(numCells, numStim);
AUC_MB = zeros(numCells, numStim);
MAX_MB = zeros(numCells, numStim);
STDBASE_MB = zeros(numCells, numStim);
dF_F_M = []; % Clear these (have data from pre-drift correction)
dF_F_B = [];
dF_F_MB = [];
Cell = zeros(numCells, 1);
for C = 1:numCells
    currCellStruct = dataStruct.ROIdata(C);
    Cell(C, 1) = C;
    dF_F_M(C, :) = currCellStruct.After_Drift_M_dF_F'; %#ok<SAGROW>
    dF_F_B(C, :) = currCellStruct.After_Drift_B_dF_F'; %#ok<SAGROW>
    dF_F_MB(C, :) = currCellStruct.After_Drift_MBDIFF_dF_F; %#ok<SAGROW> Main - background        
    AUC_M(C, :) = currCellStruct.After_Drift_M_AUC';
    AUC_B(C, :) = currCellStruct.After_Drift_B_AUC';
    AUC_MB(C, :) = currCellStruct.After_Drift_MBDIFF_AUC';  
    MAX_M(C, :) = currCellStruct.After_Drift_M_Max';
    MAX_B(C, :) = currCellStruct.After_Drift_B_Max';
    MAX_MB(C, :) = currCellStruct.After_Drift_MBDIFF_Max';
    STDBASE_M(C, :) = currCellStruct.After_Drift_M_baseStd';
    STDBASE_B(C, :) = currCellStruct.After_Drift_B_baseStd';
    STDBASE_MB(C, :) = currCellStruct.After_Drift_MBDIFF_baseStd';
end
cellT = array2table(Cell);

dffM = array2table(dF_F_M);
dffB = array2table(dF_F_B);
dffMB = array2table(dF_F_MB);

aucMT = array2table(AUC_M);
aucBT = array2table(AUC_B);
aucMBT = array2table(AUC_MB);

maxMT = array2table(MAX_M);
maxBT = array2table(MAX_B);
maxMBT = array2table(MAX_MB);

stdBaseMT = array2table(STDBASE_M);
stdBaseBT = array2table(STDBASE_B);
stdBaseMBT = array2table(STDBASE_MB);

T1 = horzcat(cellT, aucBT, eT1, aucMT, eT2, aucMBT, eT3); % Cell and AUC portions
T2 = horzcat(maxBT, eT4, maxMT, eT5, maxMBT, eT6); % Max
T3 = horzcat(stdBaseBT, eT7, stdBaseMT, eT8, stdBaseMBT, eT9); % STDBASE
T4 = horzcat(dffB, eT10, dffM, eT11, dffMB);
finTable = horzcat(T1, T2, T3, T4); % Should always be background, main, then main-background
%finTable = horzcat(cellT, aucBT, eT1, aucMT, eT2, maxBT, eT3, maxMT, eT4, stdBaseBT, eT5, stdBaseMT, eT6, dffM, eT7, dffB, eT8, dffMB);
writetable(finTable, excelName, 'Sheet', driftSheetName, 'Range', 'B4');
%% Initialize per cell sheets
for S = 1:size(stimTable, 1); stimulusNumber(S, 1) = S; end %#ok<SAGROW>
stimTable = horzcat(table(stimulusNumber), stimTable);
varNames = {'Stim number', 'Stim start frame', 'Stim end frame', 'Baseline start frame', 'Baseline end frame'};
stimTable.Properties.VariableNames = varNames;
writetable(table(driftFactor), excelName, 'Sheet', 'INFO');
writetable(table(procDate), excelName, 'Sheet', 'INFO', 'Range', 'B1');
writetable(stimTable, excelName, 'Sheet', 'INFO', 'Range', 'C1');
%% Write a sheet in excel for each cell
endRow = 0;
for N = 1:size(roiData, 2)
    currRoi = roiData(N);
    R1 = currRoi.MainName;
    R2 = currRoi.BackgroundName;
    endRow = endRow+2; % 2, 4, 6, etc
    startRow = endRow-1; % 1, 3, 5, etc
    ROIName{startRow, 1} = R1; %#ok<SAGROW>
    ROIName{endRow, 1} = R2; %#ok<SAGROW>
    BDMain_dF_F = currRoi.Before_Drift_M_dF_F;
    BDBack_dF_F = currRoi.Before_Drift_B_dF_F;
    ADMain_dF_F = currRoi.After_Drift_M_dF_F;
    ADBack_dF_F = currRoi.After_Drift_B_dF_F;
    BDMainMinusBack_dF_F = currRoi.Before_Drift_MBDIFF_dF_F;
    ADMainMinusBack_dF_F = currRoi.After_Drift_MBDIFF_dF_F;    
    dF_Ftable = table(BDMain_dF_F, BDBack_dF_F, ADMain_dF_F, ADBack_dF_F, BDMainMinusBack_dF_F, ADMainMinusBack_dF_F);
    sheetName = strcat('Cell #', R1(1:end-1));
    writetable(dF_Ftable, excelName, 'Sheet', sheetName);
    perStimStruct = currRoi;
    perStimStruct = rmfield(perStimStruct, 'MainName');
    perStimStruct = rmfield(perStimStruct, 'BackgroundName');
    perStimStruct = rmfield(perStimStruct, 'Before_Drift_M_dF_F');
    perStimStruct = rmfield(perStimStruct, 'Before_Drift_B_dF_F');
    perStimStruct = rmfield(perStimStruct, 'After_Drift_M_dF_F');
    perStimStruct = rmfield(perStimStruct, 'After_Drift_B_dF_F');
    perStimStruct = rmfield(perStimStruct, 'Before_Drift_MBDIFF_dF_F');
    perStimStruct = rmfield(perStimStruct, 'After_Drift_MBDIFF_dF_F');
    stimulusNumber = zeros(size(perStimStruct.Before_Drift_B_AUC));
    for S = 1:size(perStimStruct.Before_Drift_B_AUC, 1); stimulusNumber(S, 1) = S; end
    writetable(table(stimulusNumber), excelName, 'Sheet', sheetName, 'Range', 'G1');
    perStimTable = struct2table(perStimStruct);
    writetable(perStimTable, excelName, 'Sheet', sheetName, 'Range', 'H1'); 
end
clearvars -except dataStruct
disp('Program finished. All processing/writing finished succesfully');