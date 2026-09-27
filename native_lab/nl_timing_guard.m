function nl_timing_guard(method,scan,seconds,steadySeconds,firstCall,cfg)
% Cold native initialization and steady-state steps have separate budgets.
if firstCall
 limit=cfg.max_initialization_seconds;
 kind='initialization';
else
 limit=cfg.max_scan_seconds;
 kind='steady scan';
end
if seconds>limit
 error('NativeLab:TimeLimit','%s | scan %d | %s %.3f s > %.3f s limit. No incomplete score reported.', ...
  method,scan,kind,seconds,limit);
end
if steadySeconds>cfg.max_run_seconds
 error('NativeLab:TimeLimit','%s | scan %d | accumulated steady time %.3f s > %.3f s limit.', ...
  method,scan,steadySeconds,cfg.max_run_seconds);
end
end
