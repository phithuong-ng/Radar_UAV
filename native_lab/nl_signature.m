function signature=nl_signature(c)
% Sensor data can be replayed with different trackers; IQ lab is independent.
c=rmfield(c,{'tracking','method','iq'});signature=jsonencode(c);
end
