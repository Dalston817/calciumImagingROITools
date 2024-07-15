 
% % This scripts is to analyze data in the case that too many roi in single
% image.  The first step is to draw roi in ImageJ and then save as zip file.
% As the oval roi in ImageJ doesn't have angle,so to draw ellipse in
% matlab, the Angle is default as zero.
%                                                 
 
%% load image
clc;clear;close all;

%% define how many points (scans) until the first stimulus
%% this will set the baseline, or F0
baseline=input('how many scans until first stimulus: ');
baseline;

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
% draw roi's onto Matlab figure of ganglion
figure(1); imagesc(ref);axis image;axis off;
for i=1:Roi_num
        hold on;
        plot(mRoi{1,i}.xi,mRoi{i}.yi,'Color','k','LineWidth',1);
        text(mRoi{i}.center(1), mRoi{i}.center(2), num2str(i),...
            'Color', 'k', 'FontWeight','Bold');
end
 
%% calculate roi (mean intensity) versus time. Mean intensity = "dF"
for i=1:Roi_num
    A=repmat(mRoi{1,i}.BW,[1,1,size(Im,3)]); A=int16(A);
    df1=squeeze(sum(sum(Im.*A,1),2))/sum(sum(mRoi{1,i}.BW,1),2);
    df1=df1';
    dF(i,:)=df1;
end
 
 %% plot dF/F0 vs time, where dF=ROI intensity, F0=mean of 1st 119 ROI points, and dF_F=dF/F0
 %% dF_F are the RAW data points
 %% df_f are the SMOOTHED data points
 F0=repmat(mean(dF(:,1:28),2),1,size(dF,2));
 dF_F=(dF)./F0;
 N=size(dF_F,1);  
 for i=1:N
     df_f2=smooth(dF_F(i,:),3);
     df_f(i,:)=df_f2;
 end
 Iminfo.df_f=df_f;   
 Iminfo.df=dF;   
 Iminfo.F0=F0;
 
 figure;plot(1:size(df_f,2),df_f);
 hold on; ylabel('dF/F');xlabel('Frame No.');
 hold off;
 
 %%calculate the baseline for each cell = "base" from smoothed data.
 %%this averages the first n points, as defined by "baseline" that you
 %%entered above
  base=mean(df_f(:,1:baseline),2);
  %%calculate the stand dev of the baseling for 1st n points
  standdev=std(df_f(:,1:baseline),0,2);
 
 
 %% the following displays data in df_f as a heatmap (aka colormap)
 %% if you wish, change the colormap LUT by typing>>colormapeditor in Command window and making changes there
 %% if you want to save the LUT changes, in  Command window type: 
 %%>> mycmap = colormap(gca)  
 %%>> save('MyColormaps','mycmap')


 load('MyColormaps.mat', 'mycmap');
 figure;imagesc(df_f); colormap(mycmap);
 colorbar;

 xlabel('Frame No.');
 ylabel('cell number');
 title(Iminfo.FileName(1:9));
 hold on;
 
 
 
 %% the following superimposes vertical lines at x intervals of 30 (see line 119) 
 %% see the mathworks blog, http://blogs.mathworks.com/steve/2007/01/01/superimposing-line-plots/ 
 j=i+0.5;
N=Iminfo.frameNo;
for k = 0:30:N
    x = [k k];
    y = [0 j];
    plot(x,y,'Color','w');
    plot(x,y,'Color','w');
end
hold off;

 
[filename pathname]=uiputfile('.mat','Save the Results','/Users/anwu/desktop/');
save(fullfile(pathname,filename),'Iminfo');
 
RESULT=cat(2,AUC,MAX,dF_F);
 load('MyColormaps.mat', 'mycmap');
 w=2*stimnumber+1;
 figure;imagesc(RESULT(:,w:620)); colormap(mycmap);
 colorbar;
 
 SORT=sortrows(RESULT,-7);
figure;imagesc(SORT(:,w:620)); colormap(mycmap);
 colorbar;

