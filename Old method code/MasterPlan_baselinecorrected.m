% The 1st part of this script is An Wu's script for analyzing data.
% The first step is to draw ROIs in ImageJ and then save as zip file.
% Because oval ROIs in ImageJ don't have an angle, draw ellipse shapes in
% matlab with the Angle default as zero.
%                                                
 
%% load image
clc;clear;close all ;
[Im,Iminfo]=load1p;
 
Iminfo.frameNo=size(Im,3);
ref=mean(Im,3);
 
%% load roi
Iminfo.roipa=[Iminfo.path(1:end-3) 'zip' ];
Roi=ReadImageJROI(Iminfo.roipa);
Roi_num=length(Roi);
[row,col]=size(ref);
mRoi=cell(1,Roi_num);
%% draw roi in matlab matrix
for i=1:Roi_num
    if strcmpi(Roi{1,i}.strType, 'Oval' )  %check the Roi type
        % get the center position
        xc=1/2*(Roi{1,i}.vnRectBounds(2)+Roi{1,i}.vnRectBounds(4));
        yc=1/2*(Roi{1,i}.vnRectBounds(1)+Roi{1,i}.vnRectBounds(3));
        a=1/2*(Roi{1,i}.vnRectBounds(4)-Roi{1,i}.vnRectBounds(2));
        b=1/2*(Roi{1,i}.vnRectBounds(3)-Roi{1,i}.vnRectBounds(1));
        alfa=linspace(0,360,16).*(pi/180);  % use 16 points to draw the ellipse
        % get points on the ellipse
        xi=xc+a.*cos(alfa);
        yi=yc+b.*sin(alfa);
        % save the parameter of the roi
        % xi yi          the points on the ellipse
        % center         the position of the ceter of the ellipse
        % area           the area of the ellipse
        % x              the row range of the image
        % y              the column range of the image
        % BW             mask of the roi
        %ncEllipBounds    the bounds of the ellipse [ top left bottom right]
        roi.xi=xi;
        roi.yi=yi;
        roi.center=[xc yc];
        roi.area=polyarea(roi.xi,roi.yi);
        roi.x=[1 row];
        roi.y=[1 col];
        roi.BW=poly2mask(xi,yi,row,col);
        roi.ncEllipBounds=Roi{1,i}.vnRectBounds;
               
    else
      if strcmpi(Roi{1,i}.strType, 'Polygon' ) % check the roi type
          % xi yi             the points on the  polygon
          % x y               the row/column range of the image
          % BW                the mask of the roi
         
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
 
%% calculate the intensity dynamics in roi regions
for i=1:Roi_num
    A=repmat(mRoi{1,i}.BW,[1,1,size(Im,3)]); A=int16(A);
    df1=squeeze(sum(sum(Im.*A,1),2))/sum(sum(mRoi{1,i}.BW,1),2);
    df1=df1';
    dF(i,:)=df1;
end
 
 %% plot dF vs time
 F0=repmat(mean(dF(:,1:50),2),1,size(dF,2));
 dF_F=(dF-F0)./F0;
 N=size(dF_F,1); 
 for i=1:N
     df_f2=smooth(dF_F(i,:),3);
     df_f(i,:)=df_f2;
 end
 
 
%%input data from dF_F after running MatLab original script (e.g.
%%"df_o_SR_60points.m"
 
data=dF_F;
[cellnum scans]=size(data);
 
%%establish the cutoff criterion (how many st dev above baseline,m) for
%%responses and set the baseline (# of scans before 1st stim,q)
prompt = 'how many standard deviations above baseline mean is your cutoff? ';
m = input(prompt);
prompt = 'how many scans is your baseline? ';
q = input(prompt);
 
 
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
transposedata=transpose(data);
[scan cellnum] = size(transposedata);
fbase = mean(transposedata(1:q,:));
fstdev = std(transposedata(1:q,:));
clipdata = transposedata;
clipdata = data;
 
%%the following looks for any points in the baseline (1st q points) that are > (mean baseline + 2x stand dev) and
%%replaces that value with the mean baseline fluorescence.  That is, this
%%clips any large signals in the baseline (1st q points)
 
for i=1:cellnum
for row=1:q
if (clipdata(i,row)>(fbase(1,i))+2*fstdev(1,i))
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
ax = axes( 'Parent', fig);
CRITERION =  [];
CRITERION=[CRITERION; criterion];
y = [0 5];
 
max_k = cellnum;
k = 1;
while k <= max_k
CELLk=(transposedata(:,k));
CELLCRIT=ones(scans,1) * CRITERION(1,k);
graph=[CELLk,CELLCRIT];
plot(ax, graph, 'DisplayName', 'graph' );
title(['cell # ',num2str(k), '' ]);
set(gca, 'XMinorTick', 'on' );
hold(ax, 'on' );
 
for u=1:s_number
x = [StimulusArray(u,2), StimulusArray(u,2)];
    plot(ax, x,y, 'Color', 'b' );
end
hold(ax, 'off' );
 
 
was_a_key = waitforbuttonpress;
    if was_a_key && strcmp(get(fig, 'CurrentKey'), 'uparrow' )
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
    MAX(i,j+1)=max(transposedata(begin:final,i))-mean(transposedata((begin-10:begin),i));
    end
end
 
 
T = table(Cell,AUC(:,2:s_number+1),MAX(:,2:s_number+1),dF_F, 'VariableNames' ,{ 'Cell' 'AUC' 'MAX' 'dF' });
filename = 'SaraResults.xlsx';
writetable(T,filename, 'Sheet' ,1, 'Range' , 'C4' );
 
