function result=tracker_pass(m,c,cache,lastScan,tag)
% Estimation only: no access to ground truth. Soft time limits checked between calls.
result=struct('status','PASS','message','','estimates',{cell(lastScan,1)},'ids',{cell(lastScan,1)}, ...
 'timing',nan(lastScan,1),'completed_scans',0,'wall_seconds',0,'initialization_seconds',NaN);
runClock=tic;initialized=false;
try
 initClock=tic;tracker=make_tracker(m,cache.sensor,c);result.initialization_seconds=toc(initClock);
 for k=1:lastScan
  if m.frame=="spherical",dets=cache.spherical{k};else,dets=cache.cartesian{k};end
  if k==1 || mod(k-1,20)==0,fprintf('    %s | scan %d/%d | reports %d\n',tag,k,lastScan,numel(dets));drawnow;end
  stepClock=tic;
  if ~initialized && isempty(dets)
   xyz=zeros(0,3);ids=zeros(0,1);
  else
   tracks=tracker(dets,cache.times(k));initialized=true;
   [xyz,ids]=track_positions(tracks,m.init);
   assert(all(isfinite(xyz(:))),'Non-finite track state');
  end
  result.timing(k)=toc(stepClock);result.estimates{k}=xyz;result.ids{k}=ids;result.completed_scans=k;
  if toc(runClock)>c.max_run_seconds || result.timing(k)>c.max_scan_seconds
   result.status='TIME_LIMIT';result.message=sprintf('Soft time limit after scan %d; no partial result ranked.',k);break
  end
 end
catch ME
 result.status='FAILED';result.message=getReport(ME,'extended','hyperlinks','off');
end
result.wall_seconds=toc(runClock);
if ~strcmp(result.status,'PASS'),fprintf(2,'    %s: %s\n',result.status,result.message);end
end
