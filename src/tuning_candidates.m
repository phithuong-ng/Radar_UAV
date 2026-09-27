function [configs,names]=tuning_candidates(base,method,budget)
% Bounded environment-informed search. No unmeasured "best" profile is shipped.
configs=repmat(base,1,budget);names=strings(1,budget);
q=[.5 1 2 1 .7 1.5 .35 2.5 1 .8 1.3 1];
v=[70 90 110 120 90 100 60 130 100 80 110 90];
g=[20 25 32 25 20 30 18 38 28 24 30 25];
assert(budget<=12);
for j=1:budget
 c=base;c.acceleration_std_mps2=base.acceleration_std_mps2*q(j);c.jerk_std_mps3=base.jerk_std_mps3*q(j);
 c.imm_ca_jerk_std=base.imm_ca_jerk_std*q(j);c.imm_ct_accel_std=base.imm_ct_accel_std*q(j);
 c.velocity_std_mps=v(j);c.assignment_threshold=g(j);
 if j==4,c.score_confirmation=10;c.existence_confirmation=.95;c.tomht_confirmation=9;c.phd_confirmation=.55;end
 if j==5,c.score_confirmation=20;c.existence_confirmation=.995;c.confirmation_history=[7 9];c.clutter_density_scale=1.8;c.phd_extraction=.6;c.phd_confirmation=.8;end
 if j==6,c.score_deletion=-12;c.existence_deletion=1e-6;c.deletion_history=[6 8];c.pd_assumed=.8;c.tomht_deletion=-12;c.phd_death_rate=.003;end
 if j==7,c.gnn_logic='History';c.jpda_logic='History';c.confirmation_history=[6 8];c.deletion_history=[3 5];c.imm_stay_probability=.98;c.phd_extraction=.55;end
 if j==8,c.imm_stay_probability=.85;c.tomht_max_hypotheses=20;c.jpda_max_events=100;end
 if j==9,c.clutter_density_scale=.5;c.birth_rate_per_second=.3;end
 if j==10,c.pd_assumed=.95;c.confirmation_history=[3 5];end
 if j==11,c.imm_cv_accel_std=.5;c.phd_max_components=2000;end
 if j==12,c.score_confirmation=25;c.existence_confirmation=.999;c.tomht_confirmation=20;c.deletion_history=[5 7];c.birth_rate_per_second=.08;end
 % PHD has no assignment gate or history logic: vary actual mixture parameters too.
 if method.tracker=="PHD"
  extraction=[.4 .45 .5 .35 .6 .4 .55 .4 .5 .5 .4 .55];
  birth=[.08 .15 .25 .3 .08 .15 .1 .25 .3 .1 .15 .08];
  c.phd_extraction=extraction(j);c.birth_rate_per_second=birth(j);
  birthGate=[20 25 30 20 25 25 18 30 20 25 25 30];
  c.phd_birth_assignment_threshold=birthGate(j);
  if j==5,c.phd_deletion_threshold=3e-4;end
  if j==6,c.phd_deletion_threshold=3e-5;end
 end
 configs(j)=c;names(j)=sprintf('candidate_%02d',j);
end
end
