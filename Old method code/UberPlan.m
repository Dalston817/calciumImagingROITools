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

data=dF_F;
[cellnum scans]=size(data);

%%establish the cutoff criterion (how many st dev above baseline,m) for
%%responses and set the baseline (# of scans before 1st stim,q)
prompt = 'how many standard deviations above baseline mean is your cutoff? ';
m = input(prompt);

%%set the points where stim markers will appear on plot.  This
%%creates an array, "StimulusArray" with the time points for on/off for each stim



prompt = ['how many stimuli in this trial? '];
s_number = input(prompt);
StimulusArray=zeros(s_number,3);
for i=1:s_number
    query=['when is onset of stim number ',num2str(i)];
    disp(query);
    prompt = '? ';
    s_on = input(prompt);
    query=['what is endpoint for stim number ',num2str(i)];
    disp(query);
    prompt = '? ';
    s_off = input(prompt);
    StimulusArray(i,1)=i;
    StimulusArray(i,2)=s_on;
    StimulusArray(i,3)=s_off;
end
StimulusArray

%%the following calculates the mean and stand dev of first q points and
%%generates 2 arrays, fbase ("baseline fluorescence") and fstdev (stand
%%deviation of baseline fluorescence)

[scan cellnum] = size(data);
fbase = mean(data(1:q,:));
fstdev = std(data(1:q,:));
clipdata = data;

%%the following looks for any points in the baseline (1st q points) that are > (mean baseline + 2x stand dev) and
%%replaces that value with the mean baseline fluorescence.  That is, this
%%clips any large signals in the baseline (1st q points)

for i=1:cellnum
for row=1:q
if(clipdata(i,row)>(fbase(1,i))+2*fstdev(1,i))
clipdata(i,row)=fbase(1,i);
end
end
end

%%the following recalculates a new mean and new stand deviation for the
%%baseline (q points), having removed any large spontaneous signals from
%%the baseline.  Then this calculates a "criterion" for each cell that is
%%equal to the baseline of that cell + m standard deviations.  The user has
%%input m at the beginning
clipdata=transpose(clipdata);
newfbase = mean(clipdata(1:q,:));
newfstdev = std(clipdata(1:q,:));
criterion=newfbase+m*newfstdev;

    
%%the following plots the original data (now named "transposedata") for
%%each cell k with its corresponding criterion line (mean baseline + m
%%standard deviations)



fig = gcf;
ax = axes('Parent', fig); 
CRITERION =  [];
CRITERION=[CRITERION; criterion];
y = [0 5];

max_k = cellnum;
k = 1;
while k <= max_k
CELLk=(data(:,k));
CELLCRIT=ones(scans,1) * CRITERION(1,k);
graph=[CELLk,CELLCRIT];
plot(ax, graph,'DisplayName','graph');
title(['cell # ',num2str(k),'']);
set(gca,'XMinorTick','on');
hold(ax, 'on');

for u=1:s_number
x = [StimulusArray(u,2), StimulusArray(u,2)];
    plot(ax, x,y,'Color','b');
end
hold(ax, 'off');


was_a_key = waitforbuttonpress;
    if was_a_key && strcmp(get(fig, 'CurrentKey'), 'uparrow')
      k = max(1,k-1);
    else
      k = k + 1;
    end
end
 
%%% below is MeasureVariableStim


Cell=zeros(cellnum,1);
for i=1:cellnum
    Cell(i,1)=i;
end
    
AUC=zeros([cellnum s_number+1]);
for i=1:cellnum
    for j=1:s_number
    begin=StimulusArray(j,2);
    final=StimulusArray(j,3);
    AUC(i,1)=i;
    AUC(i,j+1)=trapz(transposedata(begin:final,i));
    end
   
end

MAX=zeros([cellnum s_number+1]);
for i=1:cellnum
    for j=1:s_number
    begin=StimulusArray(j,2);
    final=StimulusArray(j,3);
    MAX(i,1)=i;
    MAX(i,j+1)=max(transposedata(begin:final,i));
    end
end


T = table(Cell,AUC(:,2:s_number+1),MAX(:,2:s_number+1),dF_F,'VariableNames',{'Cell' 'AUC' 'MAX' 'dF'});
filename = 'SaraResults.xlsx';
writetable(T,filename,'Sheet',1,'Range','C4');

%the following calculates the running average ("smoothed") version of dF_F.
%the smoothed version is named df_f

 N=size(dF_F,1);  
 for i=1:N
     df_f2=smooth(dF_F(i,:),3);
     df_f(i,:)=df_f2;
 end
 
  %% the following displays data in df_f as a heatmap (aka colormap)
 %% if you wish, change the colormap LUT by typing>>colormapeditor in Command window and making changes there
 %% if you want to save the LUT changes, in  Command window type: 
 %%>> mycmap = colormap(gca)  
 %%>> save('MyColormaps','mycmap')


 load('MyColormaps.mat', 'mycmap');
 figure;imagesc(df_f); colormap(mycmap);
 colorbar;
 
 