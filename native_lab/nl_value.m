function value=nl_value(text,old)
% No str2num/eval: numeric vectors/matrices must use literal JSON notation.
text=char(string(text));
if ischar(old)||isstring(old),value=text;return;end
try,value=jsondecode(text);catch,error('Use a number, true/false, or JSON array such as [1,2,3].');end
if islogical(old)
 assert(islogical(value)&&numel(value)==numel(old),'Use true/false, or a JSON array of true/false matching the original size.');
 value=reshape(value,size(old));
else
 assert(isnumeric(value)&&isreal(value)&&all(isfinite(value),'all'),'Use finite numeric data.');
 if isempty(old),return;end
 assert(isequal(size(value),size(old))||isvector(value)&&isvector(old)&&numel(value)==numel(old),'Value has wrong size.');
 value=reshape(value,size(old));
end
end
