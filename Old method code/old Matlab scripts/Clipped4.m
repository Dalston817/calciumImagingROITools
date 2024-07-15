%%input data from dF_F after running MatLab original script (e.g.
%%"df_o_SR_60points.m"

data=dF_F;

%%establish the cutoff criterion (how many st dev above baseline,m) for
%%responses and set the baseline (# of scans before 1st stim,q)
prompt = 'how many standard deviations above baseline mean is your cutoff? ';
m = input(prompt);
prompt = 'how many scans is your baseline? ';
q = input(prompt);


%%set the points where stim markers will appear on plot.  This
%%creates an array, "stimulus" with the time points for onsets of stim
stimulus = zeros([1 20]);
prompt = ['how many stimuli in this experiment? '];
stimnumber = input(prompt);
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

for cell=1:cellnum
for row=1:q
if(clipdata(cell,row)>(fbase(1,cell))+2*fstdev(1,cell))
clipdata(cell,row)=fbase(1,cell);
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
for p=1:100

    CRITERION =  [];
    for i=1:scan
CRITERION=[CRITERION; criterion];
    end
for k=1:cellnum
CELLk=(transposedata(:,k));
plot(CELLk)
CELLCRIT=(CRITERION(:,k));
graph=[CELLk,CELLCRIT];
plot(graph,'DisplayName','graph');
set(gca,'XMinorTick','on')
hold on;

%%the following attempts to draw vertical lines from y=0 to 5 at every point the
%%user has identified as a stimulus onset. These data are stored in the
%%array "stimulus" that was generated at the outset by user input
    y = [0 5];
x = [stimulus(1,1), stimulus(1,1)];
    plot(x,y,'Color','b');
x = [stimulus(1,2), stimulus(1,2)];
    plot(x,y,'Color','b');
x = [stimulus(1,3), stimulus(1,3)];
    plot(x,y,'Color','b');
x = [stimulus(1,4), stimulus(1,4)];
    plot(x,y,'Color','b');
x = [stimulus(1,5), stimulus(1,5)];
    plot(x,y,'Color','b');
x = [stimulus(1,6), stimulus(1,6)];
    plot(x,y,'Color','b');
x = [stimulus(1,7), stimulus(1,7)];
    plot(x,y,'Color','b');
x = [stimulus(1,8), stimulus(1,8)];
    plot(x,y,'Color','b');
x = [stimulus(1,9), stimulus(1,9)];
    plot(x,y,'Color','b');
x = [stimulus(1,10), stimulus(1,10)];
    plot(x,y,'Color','b');
x = [stimulus(1,11), stimulus(1,11)];
    plot(x,y,'Color','b');
x = [stimulus(1,12), stimulus(1,12)];
    plot(x,y,'Color','b');
x = [stimulus(1,13), stimulus(1,13)];
    plot(x,y,'Color','b');
x = [stimulus(1,14), stimulus(1,14)];
    plot(x,y,'Color','b');
x = [stimulus(1,15), stimulus(1,15)];
    plot(x,y,'Color','b');
x = [stimulus(1,16), stimulus(1,16)];
    plot(x,y,'Color','b');
x = [stimulus(1,17), stimulus(1,17)];
    plot(x,y,'Color','b');
x = [stimulus(1,18), stimulus(1,18)];
    plot(x,y,'Color','b');
x = [stimulus(1,19), stimulus(1,19)];
    plot(x,y,'Color','b');
x = [stimulus(1,20), stimulus(1,20)];
    plot(x,y,'Color','b');

    title(['cell # ',num2str(k),'']);
hold off;

%%this allows the user to advance from one cell to the next by hitting any
%%keyboard button, i.e. allows the user to "scroll" through the data, cell
%%by cell
waitforbuttonpress
end

%%because this is in effect a "one-way" scroll (forward), by looping up to 100 times, 
%%the user can return to specific cells without having to exit the entire
%%script, merely by repeating the loop again and again.
end


