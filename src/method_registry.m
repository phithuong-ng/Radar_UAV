function reg=method_registry(suite)
% Seventeen native combinations. IMM is native CV/CA/CT EKF, not a custom filter.
if nargin<1, suite='extended'; end
reg=struct('name',{},'tracker',{},'init',{},'frame',{});
for tracker=["GNN","JPDA","TOMHT"]
 for model=["CV_EKF","CV_UKF","IMM_EKF","CA_UKF","CT_UKF"]
  switch model
   case "CV_EKF", init="initcvekf";
   case "CV_UKF", init="initcvukf";
   case "IMM_EKF", init="initekfimm";
   case "CA_UKF", init="initcaukf";
   case "CT_UKF", init="initctukf";
  end
  reg(end+1)=struct('name',tracker+"_"+model+"_SPH",'tracker',tracker,'init',init,'frame',"spherical"); %#ok<AGROW>
 end
end
reg(end+1)=struct('name',"GM_PHD_CV_CART",'tracker',"PHD",'init',"initcvgmphd",'frame',"cartesian");
reg(end+1)=struct('name',"GM_PHD_CA_CART",'tracker',"PHD",'init',"initcagmphd",'frame',"cartesian");
switch string(suite)
 case "light", reg=reg(1:3);
 case "standard", reg=reg([1:3 6:8 11:13 16]);
 case "extended"
 otherwise
  selected=find([reg.name]==string(suite));
  assert(numel(selected)==1,'Choose light, standard, extended or an exact method name.');
  reg=reg(selected);
end
end
