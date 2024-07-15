
clc;
dF_F=ones(5,9)
x_offset=3;
a=size(dF_F);
cell_num=a(1,1);
scan_num=a(1,2);
stagger=zeros(cell_num,(x_offset*(cell_num-1)+scan_num))
b=size(stagger)

dF_F=ones(5,9)
x_offset=3;
a=size(dF_F);
cell_num=a(1,1);
scan_num=a(1,2);
stagger=zeros(cell_num,(x_offset*(cell_num-1)+scan_num))
b=size(stagger)
for i=1:(cell_num)
    stagger(i,(x_offset*i-1):(x_offset*i-1)+(scan_num-1))=dF_F(i,:)
        for j=1:b(1,2)
        stagger(i,j)=stagger(i,j)+1
    end
end
