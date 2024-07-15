% This scripts is to analyze data in the case that too many roi in single
% image.  The first step is to draw roi in ImageJ and then save as zip file.
% As the oval roi in ImageJ doesn't have angle,so to draw ellipse in
% matlab, the Angle is default as zero.
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
    if strcmpi(Roi{1,i}.strType,'Oval')  %check the Roi type
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
      if strcmpi(Roi{1,i}.strType,'Polygon') % check the roi type
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
%%creates an array, "stimulus" with the time points for onsets of stim

prompt = ['how many stimuli in this experiment? '];
stimnumber = input(prompt);
stimulus = zeros([1 stimnumber]);
for stim=1:stimnumber
query=['when is onset of stim number ',num2str(stim)];
disp(query);
prompt = '? ';
stimulus(1,stim)=input(prompt);
end

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
CELLk=(transposedata(:,k));
CELLCRIT=ones(scans,1) * CRITERION(1,k);
graph=[CELLk,CELLCRIT];
plot(ax, graph,'DisplayName','graph');
title(['cell # ',num2str(k),'']);
set(gca,'XMinorTick','on');
hold(ax, 'on');

for u=1:stim
x = [stimulus(1,u), stimulus(1,u)];
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
 