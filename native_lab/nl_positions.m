function [xyz,ids]=nl_positions(tracks,m,c)
if m.init~="custom",[xyz,ids]=track_positions(tracks,m.init);return;end
xyz=zeros(numel(tracks),3);ids=zeros(numel(tracks),1);idx=c.custom_position_indices;
for j=1:numel(tracks)
 x=tracks(j).State;assert(max(idx)<=numel(x),'Custom position indices exceed state dimension.');
 xyz(j,:)=reshape(x(idx),1,3);ids(j)=tracks(j).TrackID;
end
end
