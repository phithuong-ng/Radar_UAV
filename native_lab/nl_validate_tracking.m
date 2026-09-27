function nl_validate_tracking(t,method)
m=nl_registry(method);
if ischar(t.jpda_max_events)||isstring(t.jpda_max_events)
 assert(strcmp(t.jpda_max_events,'all'),'JPDA events: positive integer or all.');
else,validateattributes(t.jpda_max_events,{'numeric'},{'scalar','integer','finite','positive'});end
assert(any(strcmp(t.gnn_assignment,{'Jonker-Volgenant','Munkres','Auction','MatchPairs','Custom'})),'Invalid GNN assignment.');
assert(any(strcmp(t.gnn_logic,{'History','Score'})),'GNN logic: History or Score.');
assert(any(strcmp(t.jpda_logic,{'History','Integrated'})),'JPDA logic: History or Integrated.');
validateattributes(t.filter_seed,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1});
validateattributes(t.pf_particles,{'numeric'},{'scalar','integer','positive'});
assert(any(strcmp(t.pf_resampling,{'Multinomial','Residual','Stratified','Systematic'})),'Invalid PF resampling.');
assert(t.ukf_alpha>0&&t.ukf_alpha<=1&&t.ukf_beta>=0&&isfinite(t.ukf_kappa),'Invalid UKF scaling.');
validateattributes(t.custom_position_indices,{'numeric'},{'numel',3,'positive','integer'});
if ~isempty(t.imm_transition)
 a=t.imm_transition;assert(isequal(size(a),[3 3])&&all(a>=0,'all')&&all(abs(sum(a,2)-1)<1e-9),'IMM transition: nonnegative 3x3 rows summing to 1.');
end
p=t.imm_initial_probabilities;assert(numel(p)==3&&all(p>=0)&&abs(sum(p)-1)<1e-9,'IMM probabilities: CV, CA, CT; sum = 1.');
for value={t.tracker_properties_json,t.filter_properties_json}
 p=jsondecode(value{1});assert(isstruct(p)&&isscalar(p),'Advanced properties must be a JSON object.');
end
if m.init=="custom"
 assert(isvarname(t.custom_initializer),'Set custom_initializer to a MATLAB function name.');
end
if m.tracker=="GNN"&&strcmp(t.gnn_assignment,'Custom')
 assert(isvarname(t.custom_assignment_fcn),'Set custom_assignment_fcn to a MATLAB function name.');
end
end
