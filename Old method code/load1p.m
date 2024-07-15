function [data Iminfo]=load1p(fileno)

[FileName,PathName] = uigetfile('*.tif','Select the TIF file','C:\Users\umuser\Documents\JMBreza');
path=strcat(PathName,FileName);
Iminfo.FileName=FileName;
Iminfo.path=path;

if (nargin == 0)
    INFO=imfinfo(path);
    j=length(INFO);
    x=INFO(1).Width;
    y=INFO(1).Height;
else
    example=imread(path,1);
    [y x]=size(example);
    j=fileno;
end
data=zeros(y,x,j,'int16');

handle=waitbar(0,'Loading image');
for i=1:j
    data(:,:,i)=imread(path,i);
    waitbar(i/j,handle)
end
close(handle);
disp(path);

return