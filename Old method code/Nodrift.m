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
error('roi type must be oval or polygon')
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
data=dF_F;
[cellnum scans]=size(data);
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
transposedata=transpose(data);
[scan cellnum] = size(transposedata);
fbase = mean(transposedata(1:q,:));
fstdev = std(transposedata(1:q,:));
clipdata = transposedata;
clipdata = data;
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


%%
%This is the beginning of "Nodrift"
transposedataSSx=zeros(StimulusArray(end,1)+2,1); %this creates an array filled with 0's with (number of stim +2) rows and 1 columns
                            %this array will be used to create a smooth fit
                            %using smoothing spline method. The 1st column                            %
                            %will be x values, the second column will the
                            %the y values
transposedataSSy=zeros(StimulusArray(end,1)+2,1);                       
transposedataSSx(1,1)=5;  %this places the number 5 into row 1 column 1 (i.e., x= 5 seconds)
transposedataSSx(end,1)=scan-5; %this places the the number of scans minus 5 into last row, column 1 (i.e., x= 5 seconds from end of trace)
for o=1:size(StimulusArray,1)%this loop fills the array "transposedataSSx" with the onset times (minus 5) for each stimulus in the experiment
            P1B = StimulusArray(o,2)-1;  %this is the time point just 1 sec before stim number "o"
            transposedataSSx(o+1,1)=P1B-5;
end
for n=1:cellnum
    for o=1:size(StimulusArray,1)%this loop calculates the means of dF_F for the 10 points before each stimulus onset in the experiment
            P1B = StimulusArray(o,2)-1;  %this is the time point just 1 sec before stim number "o"
            P1A = StimulusArray(o,2)-11; %this is the time point 11 sec before stim number "o"
            transposedataSSy(o+1,1)=mean((transposedata((P1A:P1B),n)));  %this calculates the mean dF_F for the 10 points before each of "o" stimuli and puts that value into the array "transposedataSSy"
    end
    Pinit = mean((transposedata(1:10,n)));  %this calculates the mean value of dF_F for the 1st 10 points of the trace
    Pend = mean((transposedata(scan-11:scan-1,n)));  %this calculates the mean value of dF_F for the last 10 points of the trace
    transposedataSSy(1,1)=Pinit;  %this puts the mean dF_F from 1st 10 points into the top of the array "transposedataSSy"
    transposedataSSy(end,1)=Pend;  %this puts the mean dF_F from last 10 points into the bottom of the array "transposedataSSy"
    smooth=fit(transposedataSSx,transposedataSSy,'smoothingspline');
    smoothfit(:,n)=feval(smooth,1:scan);
end

%% this section takes each cell trace and subtracts its smoothed trace to eliminate the drift
for n=1:cellnum
    nodrift(:,n)=transposedata(:,n)-smoothfit(:,n);  %"nodrift" is an array with original data ("transposedata") minus the array wth smoothed drift "A"
end
%%
%%This section plots each cell with blue trace=original data and red trace with drift eliminated
fig = gcf;
ax = axes('Parent', fig);
CRITERION = [];
CRITERION=[CRITERION; criterion];
max_k = cellnum;
y = [0 5];
k = 1;
while k <= max_k
CELLk=(transposedata(:,k));
CELLCRIT=ones(scans,1) * CRITERION(1,k);
graph=[CELLk,CELLCRIT];
plot(ax, graph,'DisplayName','graph');
hold on;
plot(nodrift(:,k),'Color','r');
plot(1:scan,0,'.r');
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
        AUC(i,j+1)=trapz(transposedata(begin:final,i));
    end
end
%% the following does the same as above, but for the traces that have been corrected for drift
AUCnodrift=zeros([cellnum s_number+1]);
for i=1:cellnum
    for j=1:s_number
        begin=StimulusArray(j,2);
        final=StimulusArray(j,3);
        AUCnodrift(i,1)=i;
        AUCnodrift(i,j+1)=trapz(nodrift(begin:final,i));
    end
end
%% the following finds the peak response after each stimulus for the uncorrected traces
MAX=zeros([cellnum s_number+1]);
for i=1:cellnum
    for j=1:s_number
        begin=StimulusArray(j,2);
        final=StimulusArray(j,3);
        MAX(i,1)=i;
        MAX(i,j+1)=max(transposedata(begin:final,i));
    end
end
%% the following finds the peak response after each stimulus for the drift-corrected traces
for i=1:cellnum
    for j=1:s_number
        begin=StimulusArray(j,2);
        final=StimulusArray(j,3);
        MAXnodrift(i,1)=i;
        MAXnodrift(i,j+1)=max(nodrift(begin:final,i));
    end
end
%% this section sends AUC, peak responses, and uncorrected dF_F trace to an excel table named "Uncorrected_data"
T = table(Cell,AUC(:,2:s_number+1),MAX(:,2:s_number+1),dF_F,'VariableNames',{'Cell' 'AUC' 'MAX' 'dF'});
filename = '_Uncorrected_data.xlsx';
writetable(T,filename,'Sheet',1,'Range','C4');
%% this section sends AUC, peak responses, and drift-corrected dF_F trace to an excel table named "Drift_corrected_data"
dF_Fnodrift=transpose(nodrift);
T1 = table(Cell,AUCnodrift(:,2:s_number+1),MAXnodrift(:,2:s_number+1),dF_Fnodrift,'VariableNames',{'Cell' 'AUC' 'MAX' 'dF'});
filename = '_Drift_corrected_data.xlsx';
writetable(T1,filename,'Sheet',1,'Range','C4');