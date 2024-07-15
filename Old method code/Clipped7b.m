%%this generates an array "AUC" that lists the areas under the curve (AUC)
%%for each cell
AUC=zeros([cellnum 20]);
for r=1:cellnum
    for z=1:stimnumber
    begin=stimulus(1,z);
    final=begin + 30;
    AUC(r,z)=trapz(transposedata(begin:final,r));
    end
end

MAX=zeros([cellnum 20]);
for r=1:cellnum
    for z=1:stimnumber
    begin=stimulus(1,z);
    final=begin + 30;
    MAX(r,z)=max(transposedata(begin:final,r));
    end
end

 
%%the following writes a table, T, with labeled columns.  Column 1=cell no.
%%columns 2-21 are areas under the curve for pre-specified stimuli (up to a max of 20)
%%columns 22-42 are peak responses for preselected stimuli (up to 20)
Cell=1:cellnum;
Cell=transpose(Cell);
AUC_s1=AUC(:,1);AUC_s2=AUC(:,2);AUC_s3=AUC(:,3);AUC_s4=AUC(:,4);AUC_s5=AUC(:,5);
AUC_s6=AUC(:,6);AUC_s7=AUC(:,7);AUC_s8=AUC(:,8);AUC_s9=AUC(:,9);AUC_s10=AUC(:,10);
AUC_s11=AUC(:,11);AUC_s12=AUC(:,12);AUC_s13=AUC(:,13);AUC_s14=AUC(:,14);AUC_s15=AUC(:,15);
AUC_s16=AUC(:,16);AUC_s17=AUC(:,17);AUC_s18=AUC(:,18);AUC_s19=AUC(:,19);AUC_s20=AUC(:,20);
Max_s1=MAX(:,1);Max_s2=MAX(:,2);Max_s3=MAX(:,3);Max_s4=MAX(:,4);Max_s5=MAX(:,5);
Max_s6=MAX(:,6);Max_s7=MAX(:,7);Max_s8=MAX(:,8);Max_s9=MAX(:,9);Max_s10=MAX(:,10);
Max_s11=MAX(:,11);Max_s12=MAX(:,12);Max_s13=MAX(:,13);Max_s14=MAX(:,14);Max_s15=MAX(:,15);
Max_s16=MAX(:,16);Max_s17=MAX(:,17);Max_s18=MAX(:,18);Max_s19=MAX(:,19);Max_s20=MAX(:,20);
T = table(Cell,AUC_s1,AUC_s2,AUC_s3,AUC_s4,AUC_s5,AUC_s6,AUC_s7,AUC_s8,AUC_s9,AUC_s10,AUC_s11,AUC_s12,AUC_s13,AUC_s14,AUC_s15,AUC_s16,AUC_s17,AUC_s18,AUC_s19,AUC_s20,Max_s1,Max_s2,Max_s3,Max_s4,Max_s5,Max_s6,Max_s7,Max_s8,Max_s9,Max_s10,Max_s11,Max_s12,Max_s13,Max_s14,Max_s15,Max_s16,Max_s17,Max_s18,Max_s19,Max_s20,dF_F);


filename = 'results.xlsx';
writetable(T,filename,'Sheet',1,'Range','C4');

%%the following exports the complete data, all cells and areas under curve,
%%and peak responses plus the dF_F data into an excel spreadsheet named
%%"CompleteTable.xlsx"


filename = 'CompleteTable.xlsx';
writetable(T,filename,'Sheet',1,'Range','C4');

 
 %%the following sorts RESULTS based on a specific stimulus, from high-low.
 %%you need to specify which stimulus you want to sort

m=0 
prompt = 'Do you want to sort responses on area under the curve (AUC) or peak response? For AUC enter 1, for peak enter 2: ';
n = input(prompt);
if n == 1
    prompt = 'which number stimulus do you want the AUC for? ';
    m = input(prompt);
    m=m+1;
    SortTable=sortrows(T,-m);
    filename = 'SortedByAUC.xlsx';
    writetable(SortTable,filename,'Sheet',1,'Range','C4');
    PlotSort=SortTable{:,:};
elseif n == 2
    prompt = 'which number stimulus do you want the peak for? ';
    m = input(prompt);
    m=m+21;
    SortTable=sortrows(T,-m);
    filename = 'SortedByPeak.xlsx';
    writetable(SortTable,filename,'Sheet',1,'Range','C4');
    PlotSort=SortTable{:,:};
end

load('MyColormaps.mat')
figure;imagesc(PlotSort(:,42:scans)); colormap(mycmap);
 colorbar;

