
fig = gcf;
ax = axes('Parent', fig); 
max_k = 10;
k = 1;
while k <= max_k
    trace = (data(:,k));
    plot(ax, trace)
    hold(ax, 'on');
    title(ax, ['cell # ',num2str(k),'']);
    hold(ax, 'off');
    was_a_key = waitforbuttonpress;
    if was_a_key && strcmp(get(fig, 'CurrentKey'), 'uparrow')
      k = max(1,k-1);
    else
      k = k + 1;
    end
end
