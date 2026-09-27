function T=nl_summary(log,results)
rows=cell(0,9);
for q=1:numel(results)
 r=results{q};valid=log.valid_update(:);counts=cellfun(@numel,r.ids);
 rows(end+1,:)={string(r.method),string(r.status),mean(r.ospa,'omitnan'), ...
  mean(r.gospa,'omitnan'),mean(counts(valid)),sum(cellfun(@numel,log.detections)),r.wall_seconds, ...
  string(nl_run_label(r.method,r.config)),string(jsonencode(r.config))}; %#ok<AGROW>
end
T=cell2table(rows,'VariableNames',{'Method','Status','MeanOSPA_m','MeanGOSPA_m','MeanTracks','Reports','WallSeconds','Label','TrackerConfigJSON'});
end
