clc;


prompt = 'how many stimuli? ';
s_number = input(prompt);
StimulusArray=zeros(s_number,3);
for i=1:s_number
    a=i;
    prompt = 'what is stimulus onset? ';
    s_on = input(prompt);
    prompt = 'what is stimulus endpoint? ';
    s_off = input(prompt);
    StimulusArray(a,1)=a;
    StimulusArray(a,2)=s_on;
    StimulusArray(a,3)=s_off;
end
StimulusArray

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
    MAX(i,j+1)=max(transposedata(begin:final,i));
    end
end


T = table(Cell,AUC(:,2:s_number+1),MAX(:,2:s_number+1),dF_F,'VariableNames',{'Cell' 'AUC' 'MAX' 'dF'});
filename = 'SaraResults.xlsx';
writetable(T,filename,'Sheet',1,'Range','C4');

