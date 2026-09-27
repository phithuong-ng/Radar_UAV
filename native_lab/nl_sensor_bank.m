function [sensors,scenes,faces]=nl_sensor_bank(c,scattererCount)
faces=nl_faces(c);sensors=cell(numel(faces),1);scenes=sensors;
for j=1:numel(faces)
 cc=c;cc.radar=faces(j).radar;
 [sensors{j},scenes{j}]=nl_radar(cc,scattererCount,faces(j).id);
end
end
