function lessons=nl_lessons
lessons=jsondecode(fileread(fullfile(nl_root,'native_lab','lessons','lessons_vi.json')));
end
