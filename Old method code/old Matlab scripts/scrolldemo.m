function scrolldemo
plot(1:10)
ax1 = gca;
ax2 = axes('position',get(ax1,'position'));
plot(ax2,10:-1:1)
ax3 = axes('position',get(ax1,'position'));
plot(ax3,1:10,repmat(5,1,10));
f = gcf;
set(findobj(ax2),'Visible','off');
set(findobj(ax3),'Visible','off');
set(f,'WindowKeyPressFcn',@scrollaxes)
function scrollaxes(src,evt)
allax = findobj(src,'Type','Axes');
currax = findobj(src,'Type','Axes','Visible','on');
nextdownkey = allax([2:end 1]);
nextupkey = allax([end 1:end-1]);
if strcmp(evt.Key,'downarrow')
      set(findobj(currax),'Visible','off')
      set(findobj(nextdownkey(currax==allax)),'Visible','on');
elseif strcmp(evt.Key,'uparrow')
      set(findobj(currax),'Visible','off')
      set(findobj(nextupkey(currax==allax)),'Visible','on');
end