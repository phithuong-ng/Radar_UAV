function f=init_tuned_filter(detection,name,c)
% No truth, class labels, future reports or oracle covariance used.
if string(name)=="initekfimm"
 low=c;low.acceleration_std_mps2=c.imm_cv_accel_std;
 ca=c;ca.jerk_std_mps3=c.imm_ca_jerk_std;
 ct=c;ct.acceleration_std_mps2=c.imm_ct_accel_std;
 bank={configure_filter(initcvekf(detection),'cv',low); ...
       configure_filter(initcaekf(detection),'ca',ca); ...
       configure_filter(initctekf(detection),'ct',ct)};
 f=trackingIMM(bank,@switchimm,c.imm_stay_probability, ...
     'ModelProbabilities',[.4;.3;.3],'State',bank{1}.State,'StateCovariance',bank{1}.StateCovariance);
else
 f=configure_filter(feval(char(name),detection),name,c);
end
end
