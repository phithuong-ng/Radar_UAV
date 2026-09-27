function text=nl_commands(c)
lines={ '% Generated session configuration. Run START_NATIVE_LAB once to add paths.'; ...
 '% Algorithms: waypointTrajectory/uavScenario -> radarDataGenerator -> original native tracker factory.'; ...
 '% Mapping: readgeoraster/geointerp/geodetic2enu/enu2geodetic/los2.'; ...
 'c=nl_defaults;'};
walk(c,'c');
lines=[lines;{'nl_validate(c);';'log=nl_simulate(c);';'result=nl_track(log,c);';'folder=nl_export(c,log,{result});'}];
text=strjoin(lines,newline);
 function walk(s,prefix)
  keys=fieldnames(s);
  for j=1:numel(keys)
   key=keys{j};v=s.(key);path=[prefix '.' key];
   if isstruct(v)
    if numel(v)>1||strcmp(key,'uavs')
     lines{end+1,1}=[path '=' path '(1);'];
     for q=1:numel(v),walk(v(q),sprintf('%s(%d)',path,q));end
    else,walk(v,path);end
   elseif ischar(v)||isstring(v)
    lines{end+1,1}=[path '=' char(39) strrep(char(v),char(39),repmat(char(39),1,2)) char(39) ';'];
   elseif islogical(v)
    lines{end+1,1}=[path '=logical(' mat2str(v) ');'];
   else
    lines{end+1,1}=[path '=' mat2str(v,17) ';'];
   end
  end
 end
end
