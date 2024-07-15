%%
%This script inputs your array such as "dF_F" and creates a heat map
%To use, simply replace "dF_F" in line 5 with the name of your array.
%Your array must be organized as cells=rows and scans=columns, e.g. 119x600
%It sets the color scale automatically to range from dF/F = 0 to 1.0

load('MyColormaps.mat', 'mycmap');
figure;imagesc(dF_F); colormap(mycmap);
caxis([0 1]);
colorbar;

hold on;
plot([500 500],[0,size(dF_F,1)],'w');  %this places a white vertical line at x position = 500.  Change "[500 500]" to "[x x]" set the x position or delete this line to omit any vertical lines

xlabel('Frame No.');
ylabel('cell number');
