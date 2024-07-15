
clc;
dF_F=ones(5,9)
x_offset=3;
y_offset=1;
a=size(dF_F);
cell_num=a(1,1);
scan_num=a(1,2);
stagger=zeros(cell_num,(x_offset*(cell_num-1)+scan_num));

for i=1:(cell_num)
    stagger(i,(x_offset*i-1):(x_offset*i-1)+(scan_num-1))=dF_F(i,:)
    stagger(i,:)=stagger(i,:)+i
    b=size(stagger);
end
figure;plot(1:b(1,2),stagger(:,:));