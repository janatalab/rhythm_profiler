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
inputFileList = exemplars.data{exemplarsCols.audFileList};
[classList,dummy,allClassTargets] = unique(classes);
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

classTargets = allClassTargets(idxs_used);

%remove the ratio=1 peak
removeRatios = strmatch('1',ratioLabels,'exact');
%the following would be used to remove those ratios with all zeros
%removeRatios = [removeRatios ; find(all(nnet_inputs == 0,2))];
nnet_inputs(removeRatios,:) = [];
ratioLabels(removeRatios) = [];

%normalize the rest of the peaks
nnet_inputs = nnet_inputs./max(nnet_inputs(:));

%initialize vectors used for tallying exemplar failures
failToAnswerTally = zeros(nFiles,1);
wrongAnswerTally = zeros(nFiles,1);
multiAnswerTally = zeros(nFiles,1);

nRuns = params.nnet.nRuns;

for iRun = 1:nRuns

  fprintf('Run #%d\n',iRun);
  
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
  
  trainFileIdxs = idxs_used(trainIdxs);
  testFileIdxs = idxs_used(~trainingMask);
  
  nMetricLevels = size(nnet_inputs,2);
  ranges = minmax(nnet_inputs);
  noData = find(ranges(:,1) == ranges(:,2));
  ranges(noData,:) = repmat([0 1],length(noData),1);
  
  targets = ind2vec(nnetTrainingClassTargets);
  
  nEpochs = params.nnet.trainParams.epochs;
  
  net = newff(ranges,size(targets,1),{'logsig'});
  [net,tr] = train(net,nnetTrainingInputs,targets);
  [minPerf,minEpoch] = min(tr.perf);
  
  disp('Testing neural network:');
  %verify network with test inputs
  simOutputVec = sim(net,nnetTestInputs);
  [simOutput,outIdxs] = find(simOutputVec == repmat(max(simOutputVec),4,1));
  
  multipleAnsIdx = find([1 ;diff(outIdxs)] == 0);
  
  %multipleAnsIdx contains all repeated answers
  %now, we find the first one before each block of repeats
  inBlock = find([0 ;diff(multipleAnsIdx) == 1]);
  blocks = multipleAnsIdx;
  blocks(inBlock) = [];
  firstMulti = blocks -1;
  
  if(~isempty(multipleAnsIdx))
    warning('Found multiple answers for some input vectors during simulation.');

    %setting the answer for these to NaN, and removing the repeats.
    %we won't know which two classifications were competing here.
    %however, this seems to happen on a small percentage of runs so
    %it might be fine just to find out which exemplars provided
    %competing answers
    simOutput(firstMulti) = NaN;
    simOutput(multipleAnsIdx) = [];
    outIdxs(multipleAnsIdx) = [];
  
  end

  maskMultiAnswer = isnan(simOutput);
  maskAnswered = simOutput ~= 0;
  maskGivenCorrect = maskAnswered & ~maskMultiAnswer & (simOutput == nnetTestClassTargets);
  maskGivenIncorrect = maskAnswered & ~maskMultiAnswer & (simOutput ~= nnetTestClassTargets);
  numGivenCorrect = sum(maskGivenCorrect);
  numAnswered = sum(maskAnswered & ~maskMultiAnswer);
  numTotal = length(nnetTestClassTargets);
  pctAnswered = numAnswered./numTotal.*100;
  pctCorrect = numGivenCorrect./numAnswered.*100;
  
  pctAnsweredVec(iRun) = pctAnswered;
  pctCorrectVec(iRun) = pctCorrect;
  
  %keep a count of the versions that failed
  failToAnswerTally(testFileIdxs(~maskAnswered)) = failToAnswerTally(testFileIdxs(~maskAnswered)) + 1;
  wrongAnswerTally(testFileIdxs(maskGivenIncorrect)) = ...
      wrongAnswerTally(testFileIdxs(maskGivenIncorrect)) + 1;
  multiAnswerTally(testFileIdxs(maskMultiAnswer)) = ...
      multiAnswerTally(testFileIdxs(maskMultiAnswer)) + 1;
  
  
  disp('failToAnswerTally:');
  [find(failToAnswerTally) failToAnswerTally(failToAnswerTally ~=0)]
  disp('wrongAnswerTally:');
  [find(wrongAnswerTally) wrongAnswerTally(wrongAnswerTally ~= 0)]
  disp('multiAnswertally:');
  [find(multiAnswerTally) multiAnswerTally(multiAnswerTally ~= 0)]
  
  fprintf('\nAnswers given: %d of %d (%.1f %%)\n',numAnswered,numTotal,pctAnswered);
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
  
  fprintf('Num correct: %d of %d (%.1f %%)\n',numGivenCorrect,numAnswered,pctCorrect);
  
  if(pctCorrect < 100)
    
    inCorrAnswerMat = [simOutput(maskGivenIncorrect) ...
		       nnetTestClassTargets(maskGivenIncorrect)];
    uniqueAnswerCombos = unique(inCorrAnswerMat,'rows');
    fprintf('\tOf the incorrect answers given:\n');
    for idx = 1:size(uniqueAnswerCombos,1)
      thisComboMask = inCorrAnswerMat(:,1) == uniqueAnswerCombos(idx,1) ...
	  & inCorrAnswerMat(:,2) == uniqueAnswerCombos(idx,2);
      numThisCombo = sum(thisComboMask);
      if(numThisCombo == 1)
	toBeVerb = 'was';
      else
	toBeVerb = 'were';
      end
      fprintf('\t%d belonging to the class ''%s'' %s classified as ''%s''\n',numThisCombo,classList{uniqueAnswerCombos(idx,2)},toBeVerb,classList{uniqueAnswerCombos(idx,1)});
      
    end
    
  end
  
end % for iRun

if(ismember('plotFailedTests',params.perform))
  idxsUnanswered = find(failToAnswerTally ~= 0);
  for idx = 1:length(idxsUnanswered)
    fileIdx = idxsUnanswered(idx);
    fPath = matFileList{fileIdx};
    loadRP = load(fPath);
    thisRP = loadRP.rp;
    inputFile = inputFileList{fileIdx};
    loadInput = load(inputFile);
    aud_st = loadInput.aud_st;
    plotInput{1} = thisRP;
    plotInput{2} = aud_st;
    nTimesUnanswered = failToAnswerTally(fileIdx);
    plural = char((nTimesUnanswered ~= 1).*'s');
    params.plot.fig.title = sprintf('%s - unanswered %d time%s',classes{fileIdx},nTimesUnanswered,plural);
    plot_rhythmProfile(plotInput,params.plot);    
  end
    
  idxsIncorrect = find(wrongAnswerTally > 2);
  for idx = 1:length(idxsIncorrect)
    fileIdx = idxsIncorrect(idx);
    fPath = matFileList{fileIdx};
    loadRP = load(fPath);
    thisRP = loadRP.rp;
    inputFile = inputFileList{fileIdx};
    loadInput = load(inputFile);
    aud_st = loadInput.aud_st;
    plotInput{1} = thisRP;
    plotInput{2} = aud_st;
    nTimesIncorrect = wrongAnswerTally(fileIdx);
    params.plot.fig.title = sprintf('%s - answered incorrectly %d times',classes{fileIdx},nTimesIncorrect);
    plot_rhythmProfile(plotInput,params.plot);    
  end
    
  idxsMulti = find(multiAnswerTally > 1);
  for idx = 1:length(idxsMulti)
    fileIdx = idxsMulti(idx);
    fPath = matFileList{fileIdx};
    loadRP = load(fPath);
    thisRP = loadRP.rp;
    inputFile = inputFileList{fileIdx};
    loadInput = load(inputFile);
    aud_st = loadInput.aud_st;
    plotInput{1} = thisRP;
    plotInput{2} = aud_st;
    nTimesMulti = multiAnswerTally(fileIdx);
    params.plot.fig.title = sprintf('%s - provided competing answers %d times',classes{fileIdx},nTimesMulti);
    plot_rhythmProfile(plotInput,params.plot);    
  end
  
end
  
exemplarTally = ensemble_init_data_struct;
exemplarTally.vars = {'fname' 'failToAnswerTally' 'wrongAnswerTally'};
exemplarTallyCols = set_var_col_const(exemplarTally.vars);
exemplarTally.data{exemplarTallyCols.fname} = matFileList;
exemplarTally.data{exemplarTallyCols.wrongAnswerTally} = wrongAnswerTally;
exemplarTally.data{exemplarTallyCols.failToAnswerTally} = failToAnswerTally;

outData = ensemble_init_data_struct;
outData.vars = {'mean_answer_provide','std_answer_provide',...
		'mean_answer_correct','std_answer_correct','exemplarTally'};
outDataCols = set_var_col_const(outData.vars);
outData.data{outDataCols.mean_answer_provide} = mean(pctAnsweredVec);
outData.data{outDataCols.std_answer_provide} = std(pctAnsweredVec);
outData.data{outDataCols.mean_answer_correct} = mean(pctCorrectVec);
outData.data{outDataCols.std_answer_correct} = std(pctCorrectVec);
outData.data{outDataCols.exemplarTally} = exemplarTally;

return



