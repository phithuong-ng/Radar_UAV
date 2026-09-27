function keys=nl_tracking_keys(c)
% UI shows only parameters consumed by the chosen built-in model/track logic.
t=nl_tracking_defaults(c.tracking);m=nl_registry(c.method);
keys={'measurement_variance_scale','metric_cutoff_m','max_tracks', ...
 'max_initialization_seconds','max_scan_seconds','max_run_seconds','filter_seed','tracker_properties_json'};
if m.tracker~="PHD",keys=[keys {'assignment_threshold','coarse_gate_multiplier','filter_properties_json'}];end
if m.tracker=="GNN"
 if strcmp(t.gnn_assignment,'Custom'),keys=[keys {'custom_assignment_fcn'}];end
 if strcmp(t.gnn_logic,'History'),keys=[keys {'confirmation_history','deletion_history'}];
 else,keys=[keys {'score_confirmation','score_deletion','birth_rate_per_second'}];end
elseif m.tracker=="JPDA"
 keys=[keys {'jpda_max_events'}];
 if strcmp(t.jpda_logic,'History'),keys=[keys {'confirmation_history','deletion_history'}];
 else,keys=[keys {'existence_confirmation','existence_deletion','birth_rate_per_second','phd_death_rate'}];end
elseif m.tracker=="TOMHT"
 keys=[keys {'tomht_max_hypotheses','tomht_max_branches','tomht_history_scans','tomht_confirmation','tomht_deletion','birth_rate_per_second'}];
else
 keys=[keys {'birth_rate_per_second','phd_death_rate','phd_max_components','phd_extraction','phd_confirmation', ...
  'phd_deletion_threshold','phd_merging_threshold','phd_birth_assignment_threshold'}];
end
if ~(m.tracker=="GNN"&&strcmp(t.gnn_logic,'History'))
 keys=[keys {'pd_assumed','clutter_expected_per_update','clutter_density_scale'}];
end
if m.init=="custom",keys=[keys {'custom_initializer','custom_position_indices'}];return;end
keys=[keys {'velocity_std_mps','vertical_velocity_std_mps'}];
if contains(m.init,'imm')
 keys=[keys {'imm_cv_accel_std','imm_ca_jerk_std','imm_ct_accel_std','imm_transition','imm_initial_probabilities', ...
  'initial_accel_std_mps2','initial_turn_std_degps','turn_accel_std_degps2'}];
 if isempty(t.imm_transition),keys=[keys {'imm_stay_probability'}];end
elseif contains(m.init,'initca'),keys=[keys {'jerk_std_mps3','initial_accel_std_mps2'}];
elseif contains(m.init,'initct'),keys=[keys {'acceleration_std_mps2','turn_accel_std_degps2','initial_turn_std_degps'}];
else,keys=[keys {'acceleration_std_mps2'}];end
if endsWith(m.init,'ukf'),keys=[keys {'ukf_alpha','ukf_beta','ukf_kappa'}];end
if endsWith(m.init,'pf'),keys=[keys {'pf_particles','pf_resampling'}];end
end
