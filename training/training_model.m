function file=training_model(c,out,kind)
% Build models programmatically; no prebuilt SLX is claimed as validated.
[~,tag]=fileparts(tempname);name=matlab.lang.makeValidName(['nb_' kind '_' tag]);
new_system(name);cleanup=onCleanup(@()close_system(name,0)); %#ok<NASGU>
if strcmp(kind,'altitude')
 add_block('simulink/Sources/Step',[name '/Altitude_command'],'Time','1','After',num2str(c.simulink.command_altitude_m),'Position',[40 80 70 110]);
 add_block('simulink/Continuous/Transfer Fcn',[name '/Simplified_altitude_response'],'Numerator','1','Denominator',mat2str([c.simulink.time_constant_s 1]),'Position',[140 70 270 120]);
 add_block('simulink/Sinks/To Workspace',[name '/Log'],'VariableName','altitude','SaveFormat','Timeseries','Position',[350 80 460 110]);
 add_line(name,'Altitude_command/1','Simplified_altitude_response/1');add_line(name,'Simplified_altitude_response/1','Log/1');
 set_param(name,'StopTime',num2str(c.simulink.stop_time_s),'Solver','ode45','ReturnWorkspaceOutputs','on');
 file=fullfile(out,[name '.slx']);save_system(name,file);result=sim(name);
 altitude=result.get('altitude');save(fullfile(out,'simulation.mat'),'altitude');
 f=figure('Name','Simulink altitude');plot(altitude.Time,altitude.Data);grid on;xlabel('Time s');ylabel('Altitude m');
 exportgraphics(f,fullfile(out,'altitude.png'));
else
 load_system('aerolib6dof2');blocks=find_system('aerolib6dof2','SearchDepth',1,'Type','Block');
 target=blocks(strcmp(blocks,'aerolib6dof2/6DOF (Euler Angles)'));assert(~isempty(target),'Locate the Euler Angles 6DOF block in Aerospace Blockset.');
 add_block(target{1},[name '/Rigid_body_6DOF'],'Position',[180 90 390 250]);
 % These are external forces/moments in body axes. This scaffold does not model lift or gravity.
 add_block('simulink/Sources/Constant',[name '/Body_forces_N'],'Value','[0;0;0]','Position',[30 90 90 120]);
 add_block('simulink/Sources/Constant',[name '/Body_moments_Nm'],'Value','[0;0;0]','Position',[30 160 90 190]);
 ports=get_param([name '/Rigid_body_6DOF'],'PortHandles');
 assert(numel(ports.Inport)==2,'Block has extra inputs; configure its mass/inertia mode manually.');
 add_line(name,'Body_forces_N/1','Rigid_body_6DOF/1');add_line(name,'Body_moments_Nm/1','Rigid_body_6DOF/2');
 for k=1:numel(ports.Outport)
  block=sprintf('Output_%d',k);add_block('simulink/Sinks/Terminator',[name '/' block],'Position',[480 40+35*k 500 60+35*k]);
  add_line(name,sprintf('Rigid_body_6DOF/%d',k),[block '/1']);
 end
 file=fullfile(out,[name '.slx']);save_system(name,file);
 fprintf('Built 6DOF scaffold: open model, configure mass, inertia, forces and gravity before physical interpretation.\n');
end
fprintf('Model saved: %s\n',file);
end
