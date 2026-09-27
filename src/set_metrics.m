function s=set_metrics(X,Y,c)
% OSPA p=1, cutoff c. GOSPA p=2, alpha=2. Assignment independent of tracker.
m=size(X,1); n=size(Y,1); D=zeros(m,n);
for i=1:m, D(i,:)=sqrt(sum((Y-X(i,:)).^2,2))'; end
if max(m,n)==0
 s=[0 0 0 0 0 0 NaN]; return
end
if min(m,n)==0
 s=[c c*sqrt((m+n)/2) 0 m n n-m NaN]; return
end
% For OSPA, force assignment of the smaller set using high unassignment cost.
C=min(D,c); a=matchpairs(C,2*c,'min'); idx=sub2ind(size(C),a(:,1),a(:,2));
ospa=(sum(C(idx))+c*abs(m-n))/max(m,n);
% GOSPA cost c^2/2 for each unassigned element.
a=matchpairs(D.^2,c^2/2,'min'); idx=sub2ind(size(D),a(:,1),a(:,2));
keep=D(idx)<c; a=a(keep,:); idx=sub2ind(size(D),a(:,1),a(:,2));
matched=size(a,1); missed=m-matched; falseCount=n-matched;
gospa=sqrt(sum(D(idx).^2)+(c^2/2)*(missed+falseCount));
if matched, rmse=sqrt(mean(D(idx).^2)); else, rmse=NaN; end
s=[ospa gospa matched missed falseCount n-m rmse];
end
