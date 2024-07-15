%%
%This script calculates the variance ("power") in a signal for 10 consecutive point, similar to a "moving average with window=10" but instead a "moving st dev with window'10"
%The product is an array named "var_result"
%The script opens the array "result" created in NewNoDrift_PART_A of the drift-corrected data, "result"


for i=1:size(result,1)     %i = the number of rows in the array of drift-corrected data, "result", i.e. the number of cells in the record
for j=5:(size(result,2)-5)   %this reads the array "result" beginning with the 4th point up to 5 points before the end
    var_result(i,j)=var(result(i,(j-4):(j+5)));  %this calculates the variance of 10 points around "j" and enters it into the array named "var_result"
end
end

%%
%This section plots each cell with blue trace=original data and red trace with drift eliminated

fig = gcf;
ax = axes('Parent', fig);
y = [-0.5 2];
max_k = size(result,1);  %this assigns the total number of cells, "size(result,1)" to max_k
k = 1;
while k <= max_k
plot(result(k,:),'Color',[0.929,0.855,0.22]);hold on;plot(var_result(k,:),'k');
set(gca,'Color',[0.7 0.7 0.7]);
for u=1:s_number
x = [StimulusArray(u,2), StimulusArray(u,2)];
plot(ax, x,y,'Color','b');
end
title(['cell # ',num2str(k),]);
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