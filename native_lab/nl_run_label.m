function label=nl_run_label(method,t)
t=nl_tracking_defaults(t);m=nl_registry(method);label=nl_method_label(method);
if m.tracker=="GNN",label=[label ' | ' t.gnn_assignment ' | ' t.gnn_logic];
elseif m.tracker=="JPDA",label=[label ' | ' t.jpda_logic];end
end
