function result=nl_iq(c,showFigure)
% Native homogeneous flat-ground clutter study, separate from statistical scene.
if nargin<2,showFigure=true;end
s=c.iq;fs=s.sample_rate_hz;prf=s.prf_hz;fc=c.radar.frequency_hz;C=299792458;
assert(fs>0&&prf>0&&mod(fs/prf,1)==0,'SampleRate/PRF must be a positive integer.');
assert(s.bandwidth_hz>0&&s.bandwidth_hz<=fs&&s.pulse_width_s>0&&s.pulse_width_s<1/prf,'Invalid LFM bandwidth/pulse duration.');
assert(s.max_range_m>s.height_m&&2*s.max_range_m/C+s.pulse_width_s<1/prf,'Clutter return must fit within one PRI.');
validateattributes(s.pulses,{'numeric'},{'integer','>=',2,'<=',256});
validateattributes(s.array_elements,{'numeric'},{'integer','>=',2,'<=',64});
assert(s.cfar_pfa>0&&s.cfar_pfa<1&&s.transmit_erp_w>0,'Invalid CFAR Pfa/ERP.');
assert(fs/prf*s.array_elements*s.pulses<=2e7,'IQ cube too large for interactive lab. Reduce sample rate, array or pulses.');
state=rng;cleanup=onCleanup(@()rng(state));rng(c.seed,'twister'); %#ok<NASGU>
array=phased.ULA('NumElements',s.array_elements,'ElementSpacing',C/fc/2);
wave=phased.LinearFMWaveform('SampleRate',fs,'PRF',prf,'PulseWidth',s.pulse_width_s, ...
 'SweepBandwidth',s.bandwidth_hz,'OutputFormat','Pulses','NumPulses',1);
tx=wave();nPulse=ceil(s.pulse_width_s*fs);x=sqrt(s.transmit_erp_w)*tx(1:nPulse);
clutter=constantGammaClutter('Sensor',array,'OperatingFrequency',fc,'PropagationSpeed',C, ...
 'SampleRate',fs,'PRF',prf,'Gamma',s.gamma_db,'EarthModel','Flat', ...
 'PlatformHeight',s.height_m,'PlatformSpeed',s.speed_mps,'PlatformDirection',[90;0], ...
 'MountingAngles',[0 s.depression_deg 0],'ClutterMaxRange',s.max_range_m, ...
 'ClutterAzimuthSpan',s.azimuth_span_deg,'PatchAzimuthSpan',s.patch_azimuth_deg, ...
 'TransmitSignalInputPort',true,'OutputFormat','Pulses','NumPulses',1,'SeedSource','Property','Seed',c.seed);
cube=complex(zeros(round(fs/prf),s.array_elements,s.pulses));
for k=1:s.pulses,cube(:,:,k)=clutter(x);end
coef=getMatchedFilter(wave);mf=phased.MatchedFilter('Coefficients',coef);
filtered=complex(zeros(size(cube,1),s.pulses));
for k=1:s.pulses
 % Each PRI is processed independently; include enough delay margin above.
 reset(mf);y=mf(cube(:,:,k));filtered(:,k)=y(:,1);
end
range=((0:size(cube,1)-1)'-(numel(coef)-1))/fs*C/2;
rd=fftshift(fft(filtered,[],2),2);doppler=(-floor(s.pulses/2):ceil(s.pulses/2)-1)*prf/s.pulses;
power=mean(abs(filtered).^2,2);cuts=(20:size(cube,1)-20)';
assert(~isempty(cuts),'Too few fast-time samples for CFAR.');
cfar=phased.CFARDetector('NumTrainingCells',24,'NumGuardCells',4,'ProbabilityFalseAlarm',s.cfar_pfa);
flags=cfar(power,cuts);
sv=phased.SteeringVector('SensorArray',array);az=-90:.25:90;
w=sv(fc,[s.steer_deg;0]);beam=abs(w'*sv(fc,[az;zeros(size(az))]));beam=20*log10(max(beam/max(beam),1e-6));
result=struct('config',s,'cube',cube,'range',range,'doppler',doppler,'range_doppler',rd, ...
 'power',power,'cuts',cuts,'flags',flags,'azimuth',az,'beam_db',beam, ...
 'model','constantGammaClutter: homogeneous flat ground; no UAV target or receiver noise; NOT injected into tracking');
if showFigure
 f=figure('Name','Native IQ clutter — separate flat-ground model');tiledlayout(f,2,2);
 valid=range>=0&range<=s.max_range_m;
 nexttile;imagesc(doppler,range(valid),10*log10(abs(rd(valid,:)).^2+eps));axis xy;xlabel('Doppler Hz');ylabel('Range m');colorbar;
 nexttile;plot(range(valid),10*log10(power(valid)+eps));hold on;hit=cuts(flags);hit=hit(range(hit)>=0&range(hit)<=s.max_range_m);
 plot(range(hit),10*log10(power(hit)+eps),'rx');grid on;xlabel('Range m');ylabel('Power dB');title('Clutter peaks; CFAR crossings are NOT UAV detections');
 nexttile;plot(az,beam);grid on;ylim([-60 0]);xlabel('Angle deg');ylabel('Normalized ULA beam dB');
 nexttile;axis off;text(0,.8,{'Native constantGammaClutter + LFM + matched filter + CFAR'; ...
  'Flat homogeneous ground. No DEM/OSM or UAV echo in this IQ exercise.'; ...
  'A separate model from scene false alarms and stationary point scatterers.'},'Interpreter','none');
end
end
