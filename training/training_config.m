function c=training_config(file)
if nargin<1 || strlength(string(file))==0
 file=fullfile(training_root,'training','config','default.json');
end
c=jsondecode(fileread(file));c=training_normalize(c);training_validate(c);
end
