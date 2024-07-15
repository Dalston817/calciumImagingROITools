%%
%Use this section to produce a generic stagger plot
%this takes the array named dF_F and displays it as a staggered plot to
%reveal any trends in responses.  dF_F is arranged as cells=ROWS and
%scans in the COLUMNS


clc;
ax = gca;
stagger=transpose(dF_F);
ribbon(1:size(stagger,1),stagger,0.001);
set(gca, 'YDir','reverse');

%%
%Run this section instead to produce a stagger plot with parameters similar to
%those used to present to Ajinomoto 
%In line 34, change the numbers in the brackets after 'YTick' to match the tick marks you want for the time axis(Aug 2017)
%Matlab gca (get current axes) and gcf (get current figure) as its name for the axes or figure, respectively.


set(gcf,'color','white');  %"gcf"=get current figure
stagger=transpose(dF_F);   %your input data array must have columns = cells, and rows = scans, e.g. "600 x 115 double"
ribbon(1:size(stagger,1),stagger,0.001);
set(gca, 'YDir','reverse');%"gca"=get current axes
view(gca,[-37.5 30]); %this sets the position of the viewer (the viewpoint) in terms of azimuth and elevation. 
%The higher the elevation value in the above view(ax,[-37.5 30]) (here, "30") the farther above the plot the view appears.
%changing the azimuth (here "-37.5") has less of an effect.
% Set the remaining axes properties as follows:
set(gca,'GridAlpha',0.3,'GridColor',[0.64 0.08 0.18],'PlotBoxAspectRatio',...
    [3 3 1],'XColor',[1 1 1],'XMinorTick','on','YColor',[0.64 0.08 0.18],...
    'YGrid','on','YTick',[0 30 60 90 120],'YTickLabel','','ZColor',[1 1 1],...
    'XGrid','off', 'ZGrid','off' );
%important in above to enter the YTick values you choose to display
%%
%Use this section to add lines on the y (scan) axis, e.g. to mark stimulus onset
%%hold on;
%%plot([0,size(dF_F,1)],[0 0],'r');  %this puts a red line at y=270 for example. Change that value ("270") as appropriate and repeat command to add more lines
%stimuli
