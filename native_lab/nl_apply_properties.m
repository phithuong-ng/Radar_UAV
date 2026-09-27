function obj=nl_apply_properties(obj,text,kind)
% Public property extension: JSON values only, no eval or silent fallback.
p=jsondecode(char(text));assert(isstruct(p)&&isscalar(p),'Properties must be a JSON object.');
names=fieldnames(p);
protected={'TrackLogic','Assignment','CustomAssignmentFcn','ConfirmationThreshold','DeletionThreshold', ...
 'FilterInitializationFcn','SensorConfigurations','MaxNumSensors','StateParameters', ...
 'HasCostMatrixInput','HasDetectableTrackIDsInput','HasSensorConfigurationsInput', ...
 'ClassFusionMethod','StateTransitionFcn','StateTransitionJacobianFcn', ...
 'MeasurementFcn','MeasurementJacobianFcn','MeasurementNoise','State','StateCovariance', ...
 'HasAdditiveMeasurementNoise','HasAdditiveProcessNoise','MotionModel','StateOrientation', ...
 'ProcessNoiseSamplingFcn','MeasurementLikelihoodFcn','ObjectClassID'};
for j=1:numel(names)
 key=names{j};assert(~any(strcmp(key,protected)), ...
  '%s is managed by dedicated controls or changes the data contract. See the extension guide.',key);
 assert(isprop(obj,key),'Unknown %s property %s for %s.',kind,key,class(obj));
 [oldMessage,oldID]=lastwarn;lastwarn('');
 try
  obj.(key)=p.(key);[warningMessage,warningID]=lastwarn;
  lastwarn(oldMessage,oldID);
  if strcmp(warningID,'MATLAB:system:nonRelevantProperty')
   error('NativeLab:InactiveProperty','%s',warningMessage);
  end
 catch ME,error('NativeLab:Property','%s.%s: %s',class(obj),key,ME.message);end
end
end
