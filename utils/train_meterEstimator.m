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

ratioLabels = params.ratioLabels;

%initialize nnet_inputs to 0 rows, but we want to ensure that it
%has length(ratioLabels) columns
nnet_inputs= zeros(length(ratioLabels),0);
idxs_used = [];
for iFile = 1:nFiles
  
  fPath = matFileList{iFile};
  loadRP = load(fPath);
  thisRP = loadRP.rp;
  thisRPCols = set_var_col_const(thisRP.vars);
  peakInfo = thisRP.data{thisRPCols.peakInfo};
  peakInfoCols = set_var_col_const(peakInfo.vars);
  ratios = peakInfo.data{peakInfoCols.approxRatios};
  heights = peakInfo.data{peakInfoCols.normHeight};
  
  if(~isempty(ratios))
    idxs_used(end+1) = iFile;
    [dummy,idxs1,idxs2] = intersect(ratioLabels,ratios);
    nnet_inputs(idxs1,end+1) = heights(idxs2);
  end
    
end

classTargets = classTargets(idxs_used);


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

disp('Testing neural network:');
%verify network with test inputs
simOutputVec = sim(net,nnetTestInputs);
simOutputAns = vec2ind(simOutputVec);
%vec2ind only provides values for successful model outputs
%we need to find which ones were successful 
outIdxs = any(simOutputVec);
simOutput = zeros(size(simOutputVec,2),1);
simOutput(outIdxs) = simOutputAns;

maskAnswered = simOutput ~= 0;
maskGivenCorrect = simOutput(maskAnswered) == nnetTestClassTargets(maskAnswered);
numGivenCorrect = sum(maskGivenCorrect);
numAnswered = sum(maskAnswered);
numTotal = length(nnetTestClassTargets);
pctAnswered = numAnswered./numTotal.*100;
pctCorrect = numGivenCorrect./numAnswered.*100;
fprintf('Answers given: %d of %d (%.1f %%)\n',numAnswered,numTotal,pctAnswered);

if(pctAnswered < 100)
  classListUnanswered = nnetTestClassTargets(~maskAnswered);
  uniqueClassesUnAns = unique(classListUnanswered);
  fprintf('\tOf the answers not given:\n');
  for iClass = 1:length(uniqueClassesUnAns)
    numUnAnsThisClass = sum(classListUnanswered == uniqueClassesUnAns(iClass));
    if(numUnAnsThisClass == 1)
      toBeVerb = 'was';
    else
      toBeVerb = 'were';
    end
    fprintf('\t%d %s classified as ''%s''\n',numUnAnsThisClass,toBeVerb,classList{uniqueClassesUnAns(iClass)});
    
  end
end

if(pctCorrect < 100)
  
  classListIncorrect = nnetTestClassTargets(~maskGivenCorrect);
  uniqueClassesIncorr = unique(classListIncorrect);
  fprintf('\tOf the incorrect answers given:\n');
  for iClass = 1:length(uniqueClassesIncorr)
    numIncorrThisClass = sum(classListIncorrect == uniqueClassesIncorr(iClass));
    if(numIncorrThisClass == 1)
      toBeVerb = 'was';
    else
      toBeVerb = 'were';
    end
    fprintf('\t%d %s classified as ''%s''\n',numIncorrThisClass,toBeVerb,classList{uniqueClassesIncorr(iClass)});
    
  end
  
  
  
  
end


fprintf('Num correct: %d of %d (%.1f %%)\n',numGivenCorrect,numAnswered,pctCorrect);


return


