function digest=file_sha256(path)
fid=fopen(path,'rb');assert(fid>=0,'Cannot open %s',path);closer=onCleanup(@()fclose(fid)); %#ok<NASGU>
engine=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
 bytes=fread(fid,1048576,'*uint8');engine.update(typecast(bytes,'int8'));
end
raw=typecast(engine.digest(),'uint8');digest=lower(reshape(dec2hex(raw,2)',1,[]));
end
