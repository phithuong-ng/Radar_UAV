function label=nl_method_label(name)
label=char(erase(string(name),'_SPH'));label=strrep(label,'_CART','');
label=strrep(label,'_',' · ');
end
