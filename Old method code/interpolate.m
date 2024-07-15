x=data(1,:);
v=data(2,:);
xq=data(1,:);
vq1 = interp1(data(1,:),data(2,:),xq);
plot(vq1, ':.' );
