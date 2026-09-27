function f=nl_init_filter(d,name,c)
c=nl_tracking_defaults(c);name=char(name);
if strcmp(name,'custom')
 assert(isvarname(c.custom_initializer)&&exist(c.custom_initializer,'file')~=0, ...
  'Custom initializer must be a MATLAB function on the path: filter = name(detection).');
 f=feval(c.custom_initializer,d);
elseif strcmp(name,'initekfimm')
 original=init_tuned_filter(d,name,c);bank=original.TrackingFilters;
 transition=c.imm_stay_probability;if ~isempty(c.imm_transition),transition=c.imm_transition;end
 f=trackingIMM(bank,@switchimm,transition,'ModelProbabilities',c.imm_initial_probabilities(:), ...
  'State',bank{1}.State,'StateCovariance',bank{1}.StateCovariance);
elseif endsWith(name,'pf')
 % PF.StateCovariance is read-only: initialize particles with a tuned EKF prior.
 prior=init_tuned_filter(d,strrep(name,'pf','ekf'),c);
 if contains(name,'initca'),transition=@constacc;measurement=@cameas;
 elseif contains(name,'initct'),transition=@constturn;measurement=@ctmeas;
 else,transition=@constvel;measurement=@cvmeas;end
 f=trackingPF(transition,measurement,prior.State,'StateCovariance',prior.StateCovariance, ...
  'NumParticles',c.pf_particles,'HasAdditiveProcessNoise',false, ...
  'ProcessNoise',prior.ProcessNoise,'MeasurementNoise',d.MeasurementNoise, ...
  'ResamplingMethod',c.pf_resampling);
else
 f=init_tuned_filter(d,name,c);
 if isa(f,'trackingUKF'),f.Alpha=c.ukf_alpha;f.Beta=c.ukf_beta;f.Kappa=c.ukf_kappa;end
end
f=nl_apply_properties(f,c.filter_properties_json,'filter');
end
