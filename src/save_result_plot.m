function save_result_plot(d,r,m,out,cutoff)
[~,f]=evaluate_pass(r,d.truth,cutoff,1,r.completed_scans);K=size(f,1);
fig=figure('Visible','off','Color','w','Position',[50 50 1050 820]);clean=onCleanup(@()close(fig)); %#ok<NASGU>
tl=tiledlayout(fig,3,1);title(tl,char(m.name),'Interpreter','none');
ax=nexttile(tl);plot(ax,d.times(1:K),f(:,2),'LineWidth',1.2);grid(ax,'on');ylabel(ax,'OSPA (m)');ylim(ax,[0 cutoff]);
if K==160,xline(ax,d.times(101),'--','Selection');xline(ax,d.times(131),'--','Holdout');end
ax=nexttile(tl);truthCounts=arrayfun(@(k)sum(d.truth(:,1)==k),(1:K)');
trackCounts=cellfun(@(x)size(x,1),r.estimates(1:K));plot(ax,d.times(1:K),[truthCounts trackCounts]);grid(ax,'on');ylabel(ax,'Count');legend(ax,'True UAVs','Confirmed tracks');
ax=nexttile(tl);hold(ax,'on');
for id=unique(d.truth(:,3))'
 q=d.truth(d.truth(:,3)==id & d.truth(:,1)<=K,:);plot(ax,q(:,2),vecnorm(q(:,7:9),2,2));
end
grid(ax,'on');ylabel(ax,'True speed (m/s)');xlabel(ax,'Time (s)');ylim(ax,[0 160]);
exportgraphics(fig,fullfile(out,'tracking.png'),'Resolution',130);
end
