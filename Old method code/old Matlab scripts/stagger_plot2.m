
clc;
x_offset=3;
y_offset=1;
a=size(dF_F);
cell_num=a(1,1);
scan_num=a(1,2);
stagger=[cell_num,(x_offset*(cell_num-1)+scan_num)];
fig = gcf;
ax = axes('Parent', fig); 
for i=1:(cell_num)
    stagger(i,(x_offset*i-1):(x_offset*i-1)+(scan_num-1))=dF_F(i,:);
    stagger(i,:)=stagger(i,:)+i;
    graph=[stagger(i,:)];
    plot(ax, graph,'k');
    hold(ax, 'on');
end


