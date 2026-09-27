function T=training_check(out)
% API presence is not a license checkout or a successful execution.
T=training_catalog;T.available=false(height(T),1);T.missing=strings(height(T),1);
for k=1:height(T)
 a=split(T.api(k),',');found=arrayfun(@(x)~isempty(which(char(x))),a);
 T.available(k)=all(found);T.missing(k)=strjoin(a(~found),', ');
end
disp(T(:,{'id','available','missing'}));
fprintf('Release: %s. API presence only; run training_smoke for execution tests.\n',version('-release'));
if ~strcmp(version('-release'),'2025a'),warning('Target release is R2025a.');end
if nargin>0,writetable(T,fullfile(out,'toolbox_inventory.csv'));end
end
