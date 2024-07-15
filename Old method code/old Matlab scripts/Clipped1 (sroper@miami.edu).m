data=dF_F;
prompt = 'how many standard deviations above baseline mean is your cutoff? ';
m = input(prompt);
prompt = 'how many scans is your baseline? ';
q = input(prompt);
transposedata=transpose(data);
[scan cellnum] = size(transposedata);
fbase = mean(transposedata(1:q,:));
fstdev = std(transposedata(1:q,:));
clipdata = transposedata;
clipdata = data;
for cell=1:cellnum
for row=1:q
if(clipdata(cell,row)>(fbase(1,cell))+2*fstdev(1,cell))
clipdata(cell,row)=fbase(1,cell);
end
end
end


clipdata=transpose(clipdata);
newfbase = mean(clipdata(1:q,:));
newfstdev = std(clipdata(1:q,:));
criterion=newfbase+m*newfstdev;

for p=1:100

    CRITERION =  []
    for i=1:scan
CRITERION=[CRITERION; criterion];
    end
for k=1:cellnum
CELLk=(transposedata(:,k));
plot(CELLk)
CELLCRIT=(CRITERION(:,k));
graph=[CELLk,CELLCRIT];
plot(graph,'DisplayName','graph');
hold on;
x = [200 200];
    y = [0 10];
    plot(x,y,'Color','b');
title(['cell # ',num2str(k),'']);
hold off;
waitforbuttonpress
end
end


