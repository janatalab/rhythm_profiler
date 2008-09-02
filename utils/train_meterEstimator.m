function outData = train_meterEstimator(inData,params)
%
%
%
%

searchCrit.name = 'exemplars';
searchIdx = ensemble_find_analysis_struct(inData,searchCrit);
exemplars = inData{searchIdx};
exemplarsCols = set_var_col_const(exemplars.vars);

searchCrit.name = 'ipem_proc_series';
searchIdx = ensemble_find_analysis_struct(inData,searchCrit);
ipemProc = inData{searchIdx};
ipemProcCols = set_var_col_const(ipemProc.vars);

matFileList = ipemProc.data{ipemProcCols.rp};
classes = exemplars.data{exemplarsCols.class};
[classList,dummy,classTargets] = unique(classes);
nClasses = length(classList);
nFiles = length(matFileList);

percentTrain = params.nnet.percentTrain;

for iFile = 1:nFiles
  
  fPath = matFileList{iFile};
  loadRP = load(fPath);
  thisRP = loadRP.rp;
  thisRPCols = set_var_col_const(thisRP.vars);
  peakInfo = thisRP.data{thisRPCols.peakInfo};
  peakInfoCols = set_var_col_const(peakInfo.vars);
  ratios = peakInfo.data{peakInfoCols.approxRatios};
  heights = peakInfo.data{peakInfoCols.normHeight};
 
  nnet_inputs(ratios,iFile) = heights;
  
end

trainIdxs = [];
%obtain a random sampling of training inputs for each class
%this loop just obtains the indices of the random sampling
for iClass = 1:nClasses
  classIdxs = find(classTargets == iClass);
  nThisClass = length(classIdxs);
  nTrainThisClass = round(percentTrain*nThisClass);
  randIdx = randperm(nThisClass);  
  trainIdxsThisClass = randIdx(1:nTrainThisClass);
  trainIdxs(end+1:end+length(trainIdxsThisClass)) = classIdxs(trainIdxsThisClass);
end

%assign the random sampling of inputs and class designations to
%variables. Also assign testing inputs (those not chosen for
%training) to another variable.
nnetTrainingInputs = nnet_inputs(:,trainIdxs);
nnetTrainingClassTargets = classTargets(trainIdxs);
trainingMask = zeros(size(nnet_inputs,2),1);
trainingMask(trainIdxs) = 1;
nnetTestInputs = nnet_inputs(:,~trainingMask);
nnetTestClassTargets = classTargets(~trainingMask);

nMetricLevels = size(nnet_inputs,2);
ranges = minmax(nnet_inputs);
noData = find(ranges(:,1) == ranges(:,2));
ranges(noData,:) = repmat([0 1],length(noData),1);

targets = ind2vec(nnetTrainingClassTargets);

nEpochs = params.nnet.trainParams.epochs;

optimumConvergence = false;

while ~optimumConvergence

  net = newp(ranges,size(targets,1));
  net.adaptFcn = params.nnet.adaptFcn;
  net.trainParam.epochs = nEpochs;
  net.trainParam.show = params.nnet.trainParams.show;
  net = init(net);
  [net,tr] = train(net,nnetTrainingInputs,targets);

  [minPerf,minEpoch] = min(tr.perf);

  optimumConvergence = (nEpochs == minEpoch);
  if ~optimumConvergence
    disp(sprintf('minPerf: %.5f, minEpoch: %d',minPerf,minEpoch));
    disp(sprintf(['Bypassed optimal number of epochs. ' ...
		  'Resetting #epochs to %d and retraining.'],minEpoch));
    nEpochs = minEpoch;
  end
     
end


return


