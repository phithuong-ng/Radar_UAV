function result=training_run(id,configFile,out)
% One reproducible experiment per new output directory.
if nargin<2,configFile='';end
c=training_config(configFile);T=training_catalog;idx=find(T.id==string(id),1);
assert(~isempty(idx),'Unknown lab. See training_catalog.');
if nargin<3 || isempty(out)
 base=fullfile(training_root,'results','training');if ~isfolder(base),mkdir(base);end
 [~,tag]=fileparts(tempname(base));out=fullfile(base,[char(id) '_' tag]);
end
assert(~isfolder(out),'Output folder already exists; choose a NEW folder.');mkdir(out);
writeText(fullfile(out,'config.json'),jsonencode(c,'PrettyPrint',true));
state=rng;restore=onCleanup(@()rng(state)); %#ok<NASGU>
rng(c.seed,'twister');diary(fullfile(out,'console.txt'));stopLog=onCleanup(@()diary('off')); %#ok<NASGU>
result=struct('lab',char(id),'status','RUNNING','output',out,'release',version('-release'), ...
 'seed',c.seed,'seconds',NaN,'message','');clock=tic;
try
 apis=split(T.api(idx),',');
 for a=apis',assert(~isempty(which(char(a))),'Missing API: %s',a);end
 switch string(id)
  case "01_trajectory",lab_trajectory(c,out);
  case "02_environment",lab_environment(c,out);
  case "03_radar",training_generate(c,out);
  case "04_tracking"
   [~,file]=training_generate(c,out);root=training_root;addpath(root,fullfile(root,'src'));
   summary=run_mixed('baseline','GNN_CV_EKF_SPH',fullfile(out,'tracking'),file);
   assert(all(string(summary.Status)=="PASS"),'Tracking contains incomplete or failed results.');
  case "05_signal",lab_signal(c,out);
  case "06_array",lab_array(c,out);
  case "07_uav",lab_uav(c,out);
  case "08_antenna",lab_antenna(c,out);
  case "09_navigation",lab_navigation(c,out);
  case "10_atmosphere",lab_atmosphere(c,out);
  case "11_montecarlo",lab_montecarlo(c,out);
  case "12_optimization",lab_optimization(c,out);
  case "13_simulink",training_model(c,out,'altitude');
  case "14_aerospace_blocks"
   training_model(c,out,'6dof');result.status='BUILT_NOT_SIMULATED';
  case "15_coder"
   cfg=coder.config('lib');cfg.GenerateReport=true;
   codegen('-config',cfg,'training_polar_to_enu','-args',{zeros(3,1),zeros(3,1)},'-c','-d',fullfile(out,'codegen'));
   result.status='GENERATED_NOT_COMPILED';
  case "16_3d"
   world=sim3d.World;
   actor=sim3d.Actor('ActorName','TrainingUAV','Mobility',sim3d.utils.MobilityTypes.Movable);
   createShape(actor,'box',[2 2 .5]);actor.Translation=[0 0 2];add(world,actor);
   assignin('base','training3DWorld',world);
   fprintf('World built in base workspace. Use run(training3DWorld,0.05,5) to launch viewer.\n');
   result.status='BUILT_NOT_SIMULATED';
 end
 if strcmp(result.status,'RUNNING'),result.status='PASS';end
catch ME
 result.status='FAILED';result.message=getReport(ME,'extended','hyperlinks','off');
 result.seconds=toc(clock);writeText(fullfile(out,'status.json'),jsonencode(result,'PrettyPrint',true));
 fprintf(2,'%s\n',result.message);rethrow(ME);
end
result.seconds=toc(clock);writeText(fullfile(out,'status.json'),jsonencode(result,'PrettyPrint',true));
fprintf('%s | %s | %.2fs | %s\n',id,result.status,result.seconds,out);
end
function writeText(path,s)
fid=fopen(path,'w','n','UTF-8');assert(fid>=0,'Cannot write %s',path);
cl=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',s); %#ok<NASGU>
end
function lab_trajectory(c,out)
[P,V,A,~,~,t]=training_trajectory(c);f=figure('Name','Trajectory ENU');
ax=axes(f);hold(ax,'on');
for j=1:numel(c.uavs)
 plot3(ax,P(:,1,j),P(:,2,j),P(:,3,j),'LineWidth',1.5,'DisplayName',c.uavs(j).name);
 u=c.uavs(j);scatter3(ax,u.waypoints_enu_m(:,1),u.waypoints_enu_m(:,2),u.waypoints_enu_m(:,3),25,'filled','HandleVisibility','off');
 data=table(t,P(:,1,j),P(:,2,j),P(:,3,j),vecnorm(V(:,:,j),2,2),vecnorm(A(:,:,j),2,2), ...
 'VariableNames',{'time_s','east_m','north_m','up_m','speed_mps','acceleration_mps2'});
 writetable(data,fullfile(out,sprintf('uav_%02d.csv',j)));
end
grid(ax,'on');axis(ax,'equal');view(ax,3);legend(ax,'show');xlabel(ax,'East m');ylabel(ax,'North m');zlabel(ax,'Up m');
exportgraphics(f,fullfile(out,'trajectory.png'));save(fullfile(out,'trajectory.mat'),'P','V','A','t');
end
function lab_environment(c,out)
[P,~,~,~,~,t]=training_trajectory(c);d=load(fullfile(training_root,'data','dem','terrain.mat'));
[raster,ref]=readgeoraster(fullfile(training_root,'data','dem','noibai_copernicus_glo30.tif')); %#ok<ASGLU>
f=figure('Name','DEM and line of sight');ax=axes(f);surf(ax,d.east,d.north,d.terrain,'EdgeColor','none');hold(ax,'on');
ell=wgs84Ellipsoid('meter');
for j=1:numel(c.uavs)
 p=P(:,:,j);[ground,los]=training_terrain(c,p);
 [lat,lon,h]=enu2geodetic(p(:,1),p(:,2),p(:,3),c.origin_lla(1),c.origin_lla(2),c.origin_lla(3),ell);
 writetable(table(t,lat,lon,h,p(:,3)-ground,los,'VariableNames',{'time_s','lat_deg','lon_deg','ellipsoid_h_m_assumed_origin','agl_m','los'}), ...
 fullfile(out,sprintf('environment_%02d.csv',j)));
 scatter3(ax,p(:,1),p(:,2),p(:,3),18,double(los),'filled');
end
grid(ax,'on');view(ax,3);xlabel(ax,'East m');ylabel(ax,'North m');zlabel(ax,'Relative height m');
title(ax,'Bundled relative DSM; origin ellipsoidal altitude is an explicit assumption');
exportgraphics(f,fullfile(out,'terrain_los.png'));
end
function lab_signal(c,out)
s=c.signal;fs=s.sample_rate_hz;lambda=299792458/c.radar.frequency_hz;
wave=phased.LinearFMWaveform('SampleRate',fs,'SweepBandwidth',s.bandwidth_hz, ...
 'PulseWidth',s.pulse_width_s,'PRF',s.prf_hz,'OutputFormat','Pulses','NumPulses',1);
x=wave();coef=getMatchedFilter(wave);L=numel(coef);N=numel(x);M=s.pulses;
delay=round(2*s.target_range_m/299792458*fs);assert(delay+L<N,'Echo extends beyond PRI.');
echo=[zeros(delay,1);x(1:N-delay)];slow=(0:M-1)/s.prf_hz;
fd=-2*s.target_radial_velocity_mps/lambda;
cube=echo*exp(1i*2*pi*fd*slow);
% SNR refers to mean power over the entire PRI (including pulse-off samples).
channel=comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)','SNR',s.snr_db,'SignalPower',mean(abs(cube(:)).^2));
noisy=channel(cube);
mf=phased.MatchedFilter('Coefficients',coef);y=mf(noisy);
win=hann(M,'periodic');rd=fftshift(fft(y.*win',[],2),2);
range=((0:N-1)'-(L-1))/fs*299792458/2;
velocity=-((-floor(M/2):ceil(M/2)-1)*s.prf_hz/M)*lambda/2;
[velocity,order]=sort(velocity);rd=rd(:,order);
powerProfile=mean(abs(y).^2,2);
smooth=dsp.FIRFilter('Numerator',ones(1,5)/5);smoothed=smooth(powerProfile);
detector=phased.CFARDetector('NumTrainingCells',24,'NumGuardCells',4,'ProbabilityFalseAlarm',1e-4);
cut=(30:N-30)';flags=detector(powerProfile,cut); %#ok<NASGU>
valid=find(range>0&range<c.radar.range_limits_m(2));
[~,peak]=max(powerProfile(valid));peakRange=range(valid(peak));
fprintf('Peak range %.2f m; expected %.2f m; error %.2f m. Low SNR can produce a wrong peak.\n',peakRange,s.target_range_m,peakRange-s.target_range_m);
f=figure('Name','Range Doppler');tiledlayout(f,2,1);
nexttile;imagesc(velocity,range(valid),10*log10(abs(rd(valid,:)).^2+eps));axis xy;
xlabel('Radial velocity m/s (positive receding)');ylabel('Range m');colorbar;
nexttile;plot(range(valid),10*log10(powerProfile(valid)+eps));hold on;
plot(range(valid),10*log10(smoothed(valid)+eps));xlabel('Range m');ylabel('Power dB');legend('Matched filter','DSP smoothing');grid on;
exportgraphics(f,fullfile(out,'range_doppler.png'));
save(fullfile(out,'signal.mat'),'range','velocity','rd','powerProfile','cut','flags','peakRange');
end
function lab_array(c,out)
fc=c.radar.frequency_hz;lambda=299792458/fc;
array=phased.ULA('NumElements',c.signal.array_elements,'ElementSpacing',lambda/2);
sv=phased.SteeringVector('SensorArray',array);angles=-90:.25:90;
w=sv(fc,[c.signal.steer_deg;0]);response=abs(w'*sv(fc,[angles;zeros(size(angles))]));
response=20*log10(max(response/max(response),1e-6));
f=figure('Name','Array beam');plot(angles,response);grid on;ylim([-60 0]);xlabel('Azimuth deg');ylabel('Normalized response dB');
exportgraphics(f,fullfile(out,'beam.png'));save(fullfile(out,'array.mat'),'angles','response','w');
end
function lab_uav(c,out)
assert(all(c.environment.wind_enu_mps==0),'UAV platform exercise uses native waypoint motion; set wind to zero. Drift is handled only in training_trajectory.');
[~,~,~,~,traj]=training_trajectory(c);
scene=uavScenario('UpdateRate',1/c.dt,'StopTime',(c.frames-1)*c.dt,'ReferenceLocation',c.origin_lla);
for j=1:numel(c.uavs)
 uavPlatform(c.uavs(j).name,scene,'Trajectory',traj{j},'ReferenceFrame','ENU');
end
setup(scene);f=figure('Name','UAV scenario');ax=axes(f);show3D(scene,'Parent',ax);exportgraphics(f,fullfile(out,'uav_initial.png'));
while advance(scene),end
show3D(scene,'Parent',ax);exportgraphics(f,fullfile(out,'uav_final.png'));
assignin('base','trainingUAVScenario',scene);
fprintf('All platforms are visualized for the whole scenario; birth/death filtering is in lab 03.\n');
end
function lab_antenna(c,out)
a=design(dipole,c.radar.frequency_hz);az=-180:2:180;
gain=pattern(a,c.radar.frequency_hz,az,0);
f=figure('Name','Antenna pattern');plot(az,gain);grid on;xlabel('Azimuth deg');ylabel('Directivity dBi');
exportgraphics(f,fullfile(out,'antenna.png'));save(fullfile(out,'antenna.mat'),'gain','az');
fprintf('Dipole pattern study only; not automatically inserted into the statistical radar model.\n');
end
function lab_navigation(c,out)
[P,V,A,Q,~,t]=training_trajectory(c);p=P(:,:,1);v=V(:,:,1);a=A(:,:,1);
gps=gpsSensor('ReferenceFrame','ENU','ReferenceLocation',c.origin_lla,'SampleRate',1/c.dt, ...
 'HorizontalPositionAccuracy',c.navigation.horizontal_accuracy_m,'VerticalPositionAccuracy',c.navigation.vertical_accuracy_m, ...
 'VelocityAccuracy',c.navigation.velocity_accuracy_mps);
[lla,vel]=gps(p,v);
imu=imuSensor('accel-gyro','ReferenceFrame','ENU','SampleRate',1/c.dt);
% Deliberately fixed body orientation: separates acceleration/gravity from attitude dynamics.
q=repmat(quaternion(1,0,0,0),c.frames,1);[accel,gyro]=imu(a,zeros(c.frames,3),q); %#ok<ASGLU>
writetable(table(t,lla(:,1),lla(:,2),lla(:,3),vecnorm(vel-v,2,2),'VariableNames', ...
 {'time_s','lat_deg','lon_deg','altitude_m_assumed_origin','velocity_error_mps'}),fullfile(out,'gps.csv'));
save(fullfile(out,'navigation.mat'),'t','lla','vel','accel','gyro','p','v','a','q');
f=figure('Name','Navigation sensors');tiledlayout(f,2,1);nexttile;plot(t,accel);ylabel('Accelerometer m/s^2');grid on;
nexttile;plot(t,vecnorm(vel-v,2,2));ylabel('GPS velocity error m/s');xlabel('Time s');grid on;
exportgraphics(f,fullfile(out,'navigation.png'));
end
function lab_atmosphere(c,out)
[P,V,~,~,~,t]=training_trajectory(c);
provenance=jsondecode(fileread(fullfile(training_root,'data','dem','provenance.json')));
h=P(:,3,1)+provenance.origin_height_msl;
[temperature,soundSpeed,pressure,density]=atmosisa(h);
airVelocity=V(:,:,1)-c.environment.wind_enu_mps;mach=vecnorm(airVelocity,2,2)./soundSpeed;
writetable(table(t,h,temperature,pressure,density,mach),fullfile(out,'atmosphere.csv'));
fprintf('ISA uses origin-relative height plus bundled origin MSL; geometric height approximates geopotential height for this low-altitude exercise.\n');
end
function lab_montecarlo(c,out)
N=c.monte_carlo.trials;seeds=c.seed+(1:N);scores=zeros(N,1);
if c.monte_carlo.use_parallel
 assert(~isempty(which('parpool')),'Parallel Computing Toolbox is required for parallel mode.');
 parfor k=1:N,scores(k)=trial(seeds(k),c.monte_carlo.sigma_m);end
else
 for k=1:N,scores(k)=trial(seeds(k),c.monte_carlo.sigma_m);end
end
[mu,sigma,muCI,sigmaCI]=normfit(scores); %#ok<ASGLU>
writetable(table(seeds(:),scores,'VariableNames',{'seed','position_rmse_m'}),fullfile(out,'trials.csv'));
save(fullfile(out,'montecarlo.mat'),'scores','mu','sigma','muCI','sigmaCI');
f=figure('Name','Monte Carlo');histogram(scores);xlabel('3D position RMSE m');ylabel('Trials');exportgraphics(f,fullfile(out,'montecarlo.png'));
fprintf('Measurement-noise Monte Carlo; not a tracker benchmark. Approximate normal CI for mean RMSE: %.3f .. %.3f m\n',muCI);
end
function score=trial(seed,sigma)
stream=RandStream('mt19937ar','Seed',seed);e=sigma*randn(stream,160,3);score=sqrt(mean(sum(e.^2,2)));
end
function lab_optimization(c,out)
% Synthetic calibration data split before optimization. No holdout tuning.
stream=RandStream('mt19937ar','Seed',c.seed);e=c.monte_carlo.sigma_m*randn(stream,160,3);
train=e(1:100,:);holdout=e(101:end,:);bounds=c.optimization.sigma_bounds_m;
objective=@(s)numel(train)*log(s)+sum(train(:).^2)/(2*s^2);
initial=min(max(c.optimization.sigma_assumed_m,bounds(1)),bounds(2));
[sigma,nll,exitflag,output]=fmincon(objective,initial,[],[],[],[],bounds(1),bounds(2),[],optimoptions('fmincon','Display','off'));
assert(exitflag>0,'Optimization did not converge.');
holdoutNLL=numel(holdout)*log(sigma)+sum(holdout(:).^2)/(2*sigma^2);
save(fullfile(out,'fit.mat'),'sigma','nll','exitflag','output','holdoutNLL');
fprintf('Assumed sigma %.2f -> fitted %.2f m; variance scale %.3f. Apply only after testing on independent radar data.\n', ...
 c.optimization.sigma_assumed_m,sigma,(sigma/c.optimization.sigma_assumed_m)^2);
end
