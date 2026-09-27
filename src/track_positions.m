function [p,ids]=track_positions(tracks,init)
p=zeros(numel(tracks),3); ids=zeros(numel(tracks),1);
% Explicit state conversion prevents confusing CT yaw rate with altitude.
for j=1:numel(tracks)
 x=tracks(j).State;
 if contains(init,'ctrv'), z=ctrvmeas(x,'rectangular');
 elseif contains(init,'initct'), z=ctmeas(x,'rectangular');
 elseif contains(init,'initca') || contains(init,'singer')
  z=cameas(x,'rectangular');
 else, z=cvmeas(x,'rectangular'); end
 p(j,:)=z(1:3)'; ids(j)=tracks(j).TrackID;
end
end
