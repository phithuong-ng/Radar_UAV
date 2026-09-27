function reg=nl_registry(name)
% Preserve old IDs; generate additional compatible native point-target filters.
reg=method_registry('extended');
for family=["GNN","JPDA","TOMHT"]
 for motion=["CV","CA","CT"]
  for estimator=["KF","EKF","UKF","CKF","PF"]
   if motion=="CT"&&estimator=="KF",continue;end
   if family=="JPDA"&&estimator=="PF",continue;end % Not in trackerJPDA's documented accepted filter list.
   init="init"+lower(motion)+lower(estimator);
   if any([reg.tracker]==family&[reg.init]==init),continue;end
   reg(end+1)=struct('name',family+"_"+motion+"_"+estimator+"_CART", ...
    'tracker',family,'init',init,'frame',"cartesian"); %#ok<AGROW>
  end
 end
 reg(end+1)=struct('name',family+"_CUSTOM_CART",'tracker',family,'init',"custom",'frame',"cartesian"); %#ok<AGROW>
end
if nargin>0&&~strcmp(name,'extended')
 k=find([reg.name]==string(name));assert(numel(k)==1,'Unknown native method.');reg=reg(k);
end
end
