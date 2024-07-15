% modified and annotated by S Roper (latest modification/annotation on 4/5/2017)
% The 1st part of this script is An Wu's script for analyzing data.
% The first step is to draw ROIs in ImageJ and then save as zip file.
% Because oval ROIs in ImageJ don't have an angle, draw ellipse shapes in
% matlab with the Angle default as zero.
%
%% load image
clc;clear;close all;
[Im,Iminfo]=load1p;
Iminfo.frameNo=size(Im,3);
ref=mean(Im,3);
%% load roi
Iminfo.roipa=[Iminfo.path(1:end-3) 'zip'];
Roi=ReadImageJROI(Iminfo.roipa);
Roi_num=length(Roi);
[row,col]=size(ref);
mRoi=cell(1,Roi_num);
%% draw roi in matlab matrix
for i=1:Roi_num
if strcmpi(Roi{1,i}.strType,'Oval') %check the Roi type
% get the center position
xc=1/2*(Roi{1,i}.vnRectBounds(2)+Roi{1,i}.vnRectBounds(4));
yc=1/2*(Roi{1,i}.vnRectBounds(1)+Roi{1,i}.vnRectBounds(3));
a=1/2*(Roi{1,i}.vnRectBounds(4)-Roi{1,i}.vnRectBounds(2));
b=1/2*(Roi{1,i}.vnRectBounds(3)-Roi{1,i}.vnRectBounds(1));
alfa=linspace(0,360,16).*(pi/180); % use 16 points to draw the ellipse
% get points on the ellipse
xi=xc+a.*cos(alfa);
yi=yc+b.*sin(alfa);
% save the parameter of the roi
% xi yi the points on the ellipse
% center the position of the ceter of the ellipse
% area the area of the ellipse
% x the row range of the image
% y the column range of the image
% BW mask of the roi
%ncEllipBounds the bounds of the ellipse [ top left bottom right]
roi.xi=xi;
roi.yi=yi;
roi.center=[xc yc];
roi.area=polyarea(roi.xi,roi.yi);
roi.x=[1 row];
roi.y=[1 col];
roi.BW=poly2mask(xi,yi,row,col);
roi.ncEllipBounds=Roi{1,i}.vnRectBounds;
else
if strcmpi(Roi{1,i}.strType,'Polygon') % check the roi type
% xi yi the points on the polygon
% x y the row/column range of the image
% BW the mask of the roi
% get the points and center on the polygon
xi=[Roi{1,i}.mnCoordinates(:,1); Roi{1,i}.mnCoordinates(1,1)];
yi=[Roi{1,i}.mnCoordinates(:,2); Roi{1,i}.mnCoordinates(1,2)];
x=[1 row];
y=[1 col];
xc=mean(xi(1:end-1));
yc=mean(yi(1:end-1));
roi.xi=xi;
roi.yi=yi;
roi.center=[xc yc]
roi.BW=poly2mask(xi,yi,row,col);
else
if strcmpi(Roi{1,i}.strType,'Freehand') % check the roi type
% xi yi the points on the polygon
% x y the row/column range of the image
% BW the mask of the roi
% get the points and center on the polygon
xi=[Roi{1,i}.mnCoordinates(:,1); Roi{1,i}.mnCoordinates(1,1)];
yi=[Roi{1,i}.mnCoordinates(:,2); Roi{1,i}.mnCoordinates(1,2)];
x=[1 row];
y=[1 col];
xc=mean(xi(1:end-1));
yc=mean(yi(1:end-1));
roi.xi=xi;
roi.yi=yi;
roi.center=[xc yc]
roi.BW=poly2mask(xi,yi,row,col);
else
error('roi type must be oval or polygon')
end
end
end
mRoi{i}=roi;
end
%% calculate the fluorescence intensity dynamics in roi regions
% This section creates an array, "dF", with i rows, where i = number of cells (that is,
%number of ROIs, or "Roi_num"). The number of columns = number of scans
% Thus, this section calculates the raw fluorescence data, the average
% pixel intensity for each ROI for each scan
for i=1:Roi_num
A=repmat(mRoi{1,i}.BW,[1,1,size(Im,3)]); A=int16(A);
df1=squeeze(sum(sum(Im.*A,1),2))/sum(sum(mRoi{1,i}.BW,1),2);
df1=df1';
dF(i,:)=df1;
end
%% plot dF vs time
% This section first creates and array F0 with each row = mean of 1st 9 scans of the
%above dF array. Each row of F0, then, is filled with a constant value for all
%scans (columns)
% That is, F0 = "baseline" fluorescence
% Then the script generates another array, dF_F. Each element in dF is divided by the
%baseline, F0, for that row. (Actually, dF-F0/F0 such that no
% response = 0 instead of 1)
F0=repmat(mean(dF(:,1:9),2),1,size(dF,2));
% where dF(:,1:9) is a matrix = subset of the matrix "dF', namely the 1st 9 scans
% "size(dF,2)" = the number of scans, which is the no. of columns in matrix dF, i.e. the
%2nd dimension of the dF matrix
% and "mean(dF(:,1:9),2)" is a 1 column matrix with the average
% fluorescence intensity for the first 9 scans in each row
% thus "repmat(mean(dF(:,1:9),2),1,size(dF,2))" is of the form "repmat(X,a,b)" where X=
%the matrix of average fluorescence values (1 column)
% and b = number of scans. Thus, this line of script repeats all the rows of the matrix
%"mean(dF(:,1:9),2)" b times over, where b= the number of scans.
dF_F=(dF-F0)./F0;
% this line of script creates a new matrix dF_F, where dF_F is the raw signal (dF) for each
%cell divided by its baseline F0. The operation is
% called "Right array division" where x = A./B divides each element of A by the
%corresponding element of B.
N=size(dF_F,1);
for i=1:N
df_f2=smooth(dF_F(i,:),3);
df_f(i,:)=df_f2;
end
%%
%this is the end of An Wu's script. The following builds upon the unsmoothed dF/F data,
%i.e., uses the array dF_F as input.
%input data from dF_F after running MatLab original script(e.g."df_o_SR_60points.m")
%dF_F is a #cells (rows) by #scans (columns) matrix, e.g. "50x600 double"
%data is also  a #cells (rows) by #scans (columns) matrix, e.g. "50x600 double"
data=dF_F;
transdata=transpose(data);
[cellnum scans]=size(transdata);
%%
% this section establishs a cutoff criterion (how many st dev above baseline) for
%responses and sets the baseline (# of scans before 1st stim,q)
prompt = 'how many standard deviations above baseline mean is your cutoff? ';
m = input(prompt);
prompt = 'how many scans is your baseline? ';
q = input(prompt);
prompt = 'how many stimuli in this trial? ';
%%
% the following sets points where stim markers (vertical lines) will appear
% on plot. The script creates an array, "StimulusArray" with the time points for on/off
%for each stim
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
%%
%the following calculates the mean and stand dev of first q points and generates 2 arrays,
%fbase ("baseline fluorescence") and fstdev (stand deviation of baseline fluorescence)
[scan cellnum] = size(transdata);
fbase = mean(transdata(1:q,:));
fstdev = std(transdata(1:q,:));
clipdata = transdata;
clipdata = transpose(clipdata);
%%
%the following section looks for any points in the baseline (1st q points) that are > (mean
%baseline + 2x stand dev) and
%replaces that value with the mean baseline fluorescence. That is, this removes any large
%signals in the baseline (1st q points)
for i=1:cellnum
for row=1:q
if(clipdata(i,row)>(fbase(1,i))+2*fstdev(1,i))
clipdata(i,row)=fbase(1,i);
end
end
end
%%
%the following recalculates a new mean and new stand deviation for the
%baseline (q points), having removed any large spontaneous signals from
%the baseline. Then this calculates a "criterion" for each cell that is
%equal to the baseline of that cell + m standard deviations. The user has
%input m at the beginning
clipdata=transpose(clipdata);
newfbase = mean(clipdata(1:q,:));
newfstdev = std(clipdata(1:q,:));
criterion=newfbase+m*newfstdev;

%% SELECT FACTOR TO REDUCE DRIFT
%restart from HERE if you need to abort the plotting (hit CNTRL/C, or close fig window)
%the following section attempts to eliminate drift or "wobble" in the baseline
%this creates a matrix, "result" that has all the drift-corrected values
query=['what is your cutoff factor for reducing drift and wobble (i.e. factor x st dev of baseline),e.g. try 1.25 to 3'];
disp(query);
prompt = '? ';
multiplier = input(prompt);
NoDriftdata=zeros(cellnum,scan); %create a matrix of zeros with the number of cells = #rows, and number of columns = #scan
for x=1:cellnum % DCA comment - For each ROI/cell
    % DCA Comment - c = image number in stack
    for c=1:20
        NoDriftdata(x,c)=data(x,c);
    end
    factor=multiplier*std(dF_F(x,1:30)); %this resets "factor" to be a multiplicand of the st dev of baseline
    for c=21:scan-1
        currentpoint=data(x,c);
        previouspoint=data(x,c-1);
        previousnodrift=NoDriftdata(x,c-1);
        abs1=abs(currentpoint-previouspoint);
        abs2=abs(currentpoint-previousnodrift);
        if abs1 > factor || abs2 > factor  %this says if  abs1 > factor OR abs2 > factor then execute the next line
            NoDriftdata(x,c)=mean(NoDriftdata(x,(c-4):(c-1))); %creates a matrix "NoDrift" that is dF_F w/o peaks (i.e. has eliminated stim-evoked responses)
        else  NoDriftdata(x,c)=dF_F(x,c);
        end
    end
    movingav(x,:)=movmean(NoDriftdata(x,:),10);
    result(x,:)=dF_F(x,:)-movingav(x,:); %creates a matrix, "result", that has all the drift-corrected data.  Result is the equivalent of dF_F (raw data) or "data" (also, raw data)
end
transresult=transpose(result);

%%
%This section plots each cell with blue trace=original data and red trace with drift eliminated

fig = gcf;
ax = axes('Parent', fig);
y = [-0.5 3];
max_k = cellnum;
k = 1;
while k <= max_k
plot(data(k,:),'Color',[0.929,0.855,0.22]);hold on;plot(movingav(k,:),'k'); plot(result(k,:),'Color',[0.64,0.08,0.18]);
set(gca,'Color',[0.7 0.7 0.7]);
for u=1:s_number
x = [StimulusArray(u,2), StimulusArray(u,2)];
plot(ax, x,y,'Color','b');
end
title(['cell # ',num2str(k),'','  yellow=original, black=drift, maroon=corrected']);
set(gca,'XMinorTick','on');
was_a_key = waitforbuttonpress;
    if was_a_key && strcmp(get(fig, 'CurrentKey'), 'uparrow')
      k = max(1,k-1);
    else
      k = k + 1;
    end
    hold off;
end
hold off;
%% below is MeasureVariableStim
Cell=zeros(cellnum,1);
for i=1:cellnum
    Cell(i,1)=i;
end
%% the following calculates the area under the curve (AUC) for uncorrected traces, between each stimulus onset to its
%offset
AUC=zeros([cellnum s_number+1]);
for i=1:cellnum
    for j=1:s_number
        begin=StimulusArray(j,2);
        final=StimulusArray(j,3);
        AUC(i,1)=i;
        AUC(i,j+1)=trapz(transdata(begin:final,i));
    end
end
%% the following does the same as above, but for the traces that have been corrected for drift
AUCnodrift=zeros([cellnum s_number+1]);
for i=1:cellnum
    for j=1:s_number
        begin=StimulusArray(j,2);
        final=StimulusArray(j,3);
        AUCnodrift(i,1)=i;
        AUCnodrift(i,j+1)=trapz(transresult(begin:final,i));
    end
end
%% the following finds the peak response after each stimulus for the uncorrected traces
MAX=zeros(cellnum, s_number+1);
for i=1:cellnum
        MAX(i,1)=i;
        for j=1:s_number
        begin=StimulusArray(j,2);
        final=StimulusArray(j,3);
        MAX(i,j+1)=max(transdata(begin:final,i));
    end
end
%% the following finds the peak response after each stimulus for the drift-corrected traces
for i=1:cellnum
    for j=1:s_number
        begin=StimulusArray(j,2);
        final=StimulusArray(j,3);
        MAXnodrift(i,1)=i;
        MAXnodrift(i,j+1)=max(transresult(begin:final,i));
    end
end
%% this section sends AUC, peak responses, and uncorrected dF_F trace to an excel table named "Original and Corrected_data"
file=(Iminfo.path);
filename = 'Original and Corrected_data.xlsx';
emptyCol = cell(cellnum,1);
xlswrite(filename,{file},'stimuli','A1');
xlswrite(filename,{'Stimulus details:'},'stimuli','E4');
xlswrite(filename,{file},'raw dF_F','A1'); %this creates an Excel spreadsheet named "Original and Corrected_data.xlsx" and enters the location/name of the data file in the first cell of a worksheet named "1 raw dF_F"
StimNumber=StimulusArray(:,1);  %defines the order and number of stimuli in expt
Onset=StimulusArray(:,2);  %defines the onset scan number for each stimulus
EndStim=StimulusArray(:,3);  %defines the endpoints you have established for each of the stimuli
T0=table(StimNumber, Onset, EndStim);  %writes the Stimulus Array data to a table, T0
writetable(T0,filename,'Sheet','stimuli','Range','A4');
T = table(Cell,AUC(:,2:s_number+1),emptyCol,MAX(:,2:s_number+1),emptyCol,data,'VariableNames',{'Cell' 'AUC' 'blnk' 'MAX' 'blank' 'dF'});
writetable(T,filename,'Sheet','raw dF_F','Range','b4'); %writes table T (analysis of results, including AUC and MAX and dF_F data) onto sheet "1 raw dF_F"
xlswrite(filename,{file},'drift-corrected dF_F','A1'); %creates new worksheet named "2 drift-corrected dF_F" in same Excel file and enters location/name of file being analyzed
xlswrite(filename,{' correction factor='},'drift-corrected dF_F','A2'); %writes the word "correction factor" into cell A2 of worksheet named "2 drift-corrected dF_F" 
xlswrite(filename,multiplier,'drift-corrected dF_F','C2');
T1 = table(Cell,AUCnodrift(:,2:s_number+1),emptyCol,MAXnodrift(:,2:s_number+1),emptyCol,result,'VariableNames',{'Cell' 'AUC' 'blnk' 'MAX' 'blank' 'dF'});
writetable(T1,filename,'Sheet',"drift-corrected dF_F",'Range','b4');
%%
 % the following displays "resultsmoothed" (3-point smoothed version of "result", the drift-corrected data) as a heatmap (aka colormap)
 % if you wish, change the colormap LUT by typing>>colormapeditor in Command window and making changes there
 % if you want to save the LUT changes, in  Command window type: 
 %>> mycmap = colormap(gca)  
 %>> save('MyColormaps','mycmap')



load('MyColormaps.mat', 'mycmap');
datasmoothed=movmean(data,3);
figure;imagesc(result); colormap(mycmap);
caxis([0 1]);
colorbar;

xlabel('Frame No.');
ylabel('cell number');
title(strcat(Iminfo.FileName(1:9),':raw'));
hold on;

 
 %% the following superimposes vertical lines at x intervals of 30 (see line 119) 
 % see the mathworks blog, http://blogs.mathworks.com/steve/2007/01/01/superimposing-line-plots/ 

N=Iminfo.frameNo;
for k = 0:30:N
    x = [k k];
    y = [0 cellnum];
    plot(x,y,'Color','w');
    plot(x,y,'Color','w');
end
hold off;
