
%% This Script analyzes the raw and the drift-corrected traces for MAX responses.
% run this script after running NewNoDrift_Part_A.
%% SECTION 1 [calculate MAX that meet the criterion level and plot the data]
%
%Section 1 tests whether responses are <m> times the mean + standard deviation of the 10 scans preceding the stimulus (i.e. "baseline").  
%The script asks you for the value of <m>.  Raw data and drift-corrected data are plotted side-by-side with a horizontal line drawn at the mean of the 10 previous points + <n> times the stand dev of those 10 point.  
%Stimulus onset and window in which to collect the MAX response is defined in StimulusArray.
%This creates a matrix, "cutoff", with 0's if responses < threshold criterion
%(5 x sdev) or 1's if responses > criterion

cutoff_raw=zeros(cellnum,s_number+1);  %This creates a matrix, "cutoffraw", full of zeros,with number of rows= number of cells with roi's
cutoff_corrected=zeros(cellnum,s_number+1);  %This creates a matrix, "cutoffraw", full of zeros,with number of rows= number of cells with roi'
prompt = 'how many standard deviations above baseline mean is your cutoff? ';
m = input(prompt); %the variable "m" is the factor used to multiply the stand dev set an acceptance criterior
fig = gcf;
ax = axes('Parent', fig);
y = [-0.5 3];
Y_raw=NaN(cellnum,c);   %this creates a matrix "Y" full of NaN.  This matrix will hold the criterion marks (e.g. <m> times st dev of preceding 10 points)
Y_corrected=NaN(cellnum,c);
max_k = cellnum;
k = 1;
while k <= max_k
    for o=1:cellnum
        cutoff_raw(o,1)=o;
    for j=1:s_number
    t0=StimulusArray(j,2);
    sd_raw=std(data(o,1:q)); %the variable "sdraw" is the stand dev of the 10 points preceding each stimulus 
    Y_raw(o,StimulusArray(j,2):StimulusArray(j,3))=mean((data(o,1:q)))+m*sd_raw;  %this command
    if MAX(o,j+1)<mean((data(o,1:q)))+m*sd_raw   %this tests whether the signal ("data") is < [mean of 10 points before stim + "m" stand deviations]
        cutoff_raw(o,j+1)=0;
    else
        cutoff_raw(o,j+1)=MAX(o,j+1);
    end
    subplot(1,2,1) 
    plot(data(k,:),'Color',[0.929,0.855,0.22]);hold on;
    plot(Y_raw(k,:),'k','LineWidth',2);
    set(gca,'Color',[0.7 0.7 0.7]);
    title(['cell # ',num2str(k),' , raw data']);
    sd_corrected=std(result(o,1:q)); %the variable "sd" is the stand dev of the set baseline 
    Y_corrected(o,StimulusArray(j,2):StimulusArray(j,3))=mean((result(o,1:q)))+m*sd_corrected;  %this command
    if MAXnodrift(o,j+1)<mean((result(o,1:q)))+m*sd_corrected   %this tests whether the signal ("result") is < [mean of baseline + "m" stand deviations]
        cutoff_corrected(o,j+1)=0;
    else
        cutoff_corrected(o,j+1)=MAXnodrift(o,j+1);
    end
    hold off;
    subplot(1,2,2)
    plot(result(k,:),'Color',[0.929,0.855,0.22]);hold on;
    plot(Y_corrected(k,:),'k','LineWidth',2);
    set(gca,'Color',[0.7 0.7 0.7]);
    title(['cell # ',num2str(k),' , corrected for drift']);
    end
was_a_key = waitforbuttonpress;
    if was_a_key && strcmp(get(fig, 'CurrentKey'), 'uparrow')
      k = max(1,k-1);
    else
      k = k + 1;
    end
    hold off;    
end
end

%% SECTION 2 [add the raw MAX data to an excel spreadsheet named "Original and Corrected_data]

xlswrite(filename,{file},'3 MAX for raw data','A1'); %this enters the location/name of the data file in the first cell of a worksheet named "3 MAX for raw data"
T3 = table(Cell,emptyCol,cutoff_raw(:,2:s_number+1),'VariableNames',{'Cell' 'blnk' 'MAX'});
writetable(T3,filename,'Sheet',"3 MAX for raw data",'Range','b4');
xlswrite(filename,{' threshold criterion='},'3 MAX for raw data','A2');
xlswrite(filename,m,'3 MAX for raw data','D2');
xlswrite(filename,{'x stand deviation of baseline'},'3 MAX for raw data','E2');
%%
xlswrite(filename,{file},'4 MAX for drift-corrected','A1'); %this enters the location/name of the data file in the first cell of a worksheet named "4 MAX for drift-corrected"
T4 = table(Cell,emptyCol,cutoff_corrected(:,2:s_number+1),'VariableNames',{'Cell' 'blnk' 'MAX'});
writetable(T4,filename,'Sheet',"4 MAX for drift-corrected",'Range','b4');
xlswrite(filename,{' threshold criterion='},'4 MAX for drift-corrected','A2');
xlswrite(filename,m,'4 MAX for drift-corrected','D2');
xlswrite(filename,{'x stand deviation of baseline'},'4 MAX for drift-corrected','E2');


