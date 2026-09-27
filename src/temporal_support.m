function [kept,indices,counts]=temporal_support(rows,times,c)
% Shared causal front-end, optional. Retain a report if reachable from any raw
% report in previous <=3 scans at <=150 m/s plus projected measurement error.
% Hover is allowed (zero minimum speed). No truth, labels, RCS or future input.
K=numel(times);kept=cell(K,1);indices=cell(K,1);counts=zeros(K,2);
raw=cell(K,1);rawidx=cell(K,1);
for k=1:K
 rawidx{k}=find(rows(:,1)==k);raw{k}=rows(rawidx{k},:);
end
for k=1:K
 current=raw{k};yes=true(size(current,1),1);
 if c.enabled && k>1
  yes=false(size(current,1),1);
  for lag=1:min(c.max_lag_scans,k-1)
   prev=raw{k-lag};if isempty(prev),continue;end
   maxMove=c.speed_limit_mps*(times(k)-times(k-lag));
   for i=1:size(current,1)
    if yes(i),continue;end
    delta=prev(:,3:5)-current(i,3:5);distance=sqrt(sum(delta.^2,2));
    unit=delta./max(distance,eps);Ri=reshape(current(i,6:14),3,3);
    ux=unit(:,1);uy=unit(:,2);uz=unit(:,3);
    varAlong=sum((unit*Ri).*unit,2)+prev(:,6).*ux.^2+prev(:,10).*uy.^2+prev(:,14).*uz.^2 ...
     +2*prev(:,7).*ux.*uy+2*prev(:,8).*ux.*uz+2*prev(:,11).*uy.*uz;
    yes(i)=any(distance<=maxMove+c.sigma_gate*sqrt(max(varAlong,0)));
   end
  end
 end
 indices{k}=rawidx{k}(yes);kept{k}=current(yes,:);counts(k,:)=[size(current,1),sum(yes)];
end
end
