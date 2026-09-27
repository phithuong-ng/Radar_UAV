function [stats,frames]=evaluate_pass(result,truth,cutoff,firstScan,lastScan)
% Truth enters only here, after tracker execution.
K=result.completed_scans;frames=nan(K,9);
for k=1:K
 X=truth(truth(:,1)==k,4:6);Y=result.estimates{k};
 frames(k,:)=[k set_metrics(X,Y,cutoff) result.timing(k)*1000];
end
stats=struct('ospa',Inf,'gospa',Inf,'rmse',NaN,'missed',NaN,'false_tracks',NaN,'tracking_ms',Inf,'peak_tracking_ms',Inf);
if ~strcmp(result.status,'PASS') || K<lastScan,return;end
ix=firstScan:lastScan;f=frames(ix,:);
stats.ospa=mean(f(:,2));stats.gospa=mean(f(:,3));stats.missed=mean(f(:,5));stats.false_tracks=mean(f(:,6));
valid=isfinite(f(:,8)) & f(:,4)>0;
if any(valid),stats.rmse=sqrt(sum(f(valid,4).*f(valid,8).^2)/sum(f(valid,4)));end
stats.tracking_ms=mean(f(:,9));stats.peak_tracking_ms=max(f(:,9));
end
