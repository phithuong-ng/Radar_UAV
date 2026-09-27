function write_run_report(summary,out,mode,audit)
fid=fopen(fullfile(out,'SUMMARY.html'),'w','n','UTF-8');assert(fid>=0);clean=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,['<!doctype html><html lang="vi"><meta charset="utf-8"><title>UAV tracking results</title>' ...
 '<style>body{font:15px system-ui;margin:32px;color:#18283c}table{border-collapse:collapse;font-size:12px}' ...
 'td,th{padding:8px;border:1px solid #ccd4df;text-align:right}th{background:#e9f1fa}td:first-child{text-align:left}' ...
 'img{max-width:950px;width:100%%}code{background:#eee;padding:3px}</style><h1>UAV tracking — %s</h1>'],mode);
fprintf(fid,'<p>Dataset: %s, seed %d. Native MATLAB results only. OSPA p=1, cutoff 300 m.</p>',audit.scenario,audit.seed);
if audit.locked_parameters
 fprintf(fid,'<p>Parameters frozen from a separate tuning seed. Full-run metrics evaluate this file. Holdout columns report scans 131–160 for consistency; no tuning on this file.</p>');
elseif ismember(string(mode),["tune","deep"])
 fprintf(fid,'<p>Fit: scans 1–100; selection: 101–130; holdout: 131–160. Full metrics include tuning scans and startup. Holdout is a later segment of the same trajectory.</p>');
else
 fprintf(fid,'<p>Baseline/smoke using configured starting parameters; no tuning. Smoke covers only 12 scans and is not a quality benchmark.</p>');
end
fprintf(fid,'<p>Reports retained: %d / %d. Target detections retained (offline audit): %d / %d. Preparation: %.2f s.</p>', ...
 audit.kept_reports,audit.raw_reports,audit.kept_target_reports,audit.target_reports,audit.preparation_seconds);
fprintf(fid,'<p>TIME_LIMIT/FAILED/NO_LOCKED_PARAMETERS rows are not completed accuracy results.</p>');
fprintf(fid,'<table><tr>');for j=1:width(summary),fprintf(fid,'<th>%s</th>',summary.Properties.VariableNames{j});end;fprintf(fid,'</tr>');
for i=1:height(summary)
 fprintf(fid,'<tr>');
 for j=1:width(summary)
  v=summary{i,j};if iscell(v),v=v{1};end
  if isnumeric(v),s=sprintf('%.3f',v);else,s=char(string(v));end
  s=strrep(strrep(strrep(s,'&','&amp;'),'<','&lt;'),'>','&gt;');fprintf(fid,'<td>%s</td>',s);
 end
 fprintf(fid,'</tr>');
end
fprintf(fid,'</table>');
for i=1:height(summary)
 name=char(string(summary.Method(i)));pic=fullfile(out,name,'tracking.png');
 if isfile(pic),fprintf(fid,'<h2>%s</h2><img src="%s/tracking.png" alt="OSPA, count and speed">',name,name);end
end
fprintf(fid,'</html>');
end
