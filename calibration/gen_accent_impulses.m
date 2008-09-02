function outData = gen_accent_impulses(inData,params)
%

rand('state',sum(100*clock));


barFreq = params.barFreq;
dur = params.dur;
Fs = params.Fs;
gaussFWHMms = params.gaussFWHMms;
accentPatterns = params.accentPatterns;
variances = params.variances;
varianceMethod = params.varianceMethod;
if(strcmp(varianceMethod,'quant'))
  varianceQuant = params.varianceQuant;
end
classes = params.classes;
savePath = params.savePath;
exemplarsPerClass = params.exemplarsPerClass;

gaussFWHMsamps = floor(gaussFWHMms/1000*Fs);
gaussian = gauss1D([1:Fs-1]-Fs/2,0,gaussFWHMsamps,1);

aud_st = {};
classList = {};
fileList = {};

for iaccent = 1:length(accentPatterns)
    
  accentStruct = accentPatterns{iaccent};
  accentStructLen = length(accentStruct);
  
  accentLevelAmps = unique([accentStruct]);
  accentLevelAmps = accentLevelAmps(end:-1:1);
  [tf,accentLevelLocs] = ismember(accentStruct,accentLevelAmps);
  nLevels = length(unique(accentLevelLocs));
  
  thisVariance = variances(iaccent);

  clear accentValues varAccentAmps varAccentStructs
  
  switch(varianceMethod)
    case 'quant',
     for iLevel = 1:nLevels
    
       if(iLevel == 1) 
	 accentRange = [accentLevelAmps(1)-thisVariance accentLevelAmps(1)];
       else
	 accentRange = [accentLevelAmps(iLevel)-thisVariance  accentLevelAmps(iLevel)+thisVariance];
       end
    
       accentValues(:,iLevel) = [accentRange(1):diff(accentRange)/varianceQuant:accentRange(2)];  
     end
  
     %We should have the same number of values for each level, so just
     %count the first one to find out how many there are per level
     numPerLevel = size(accentValues,1);
  
     %construct a matrix that has all the possible permutations of
     %1:numPerLevel for each level
     permuteMatrix = permuteVals(numPerLevel,nLevels);
  
     for iLevel = 1:nLevels
       varAccentAmps(:,iLevel) = accentValues(permuteMatrix(:,iLevel),iLevel);
     end
     
     for idx = 1:size(varAccentAmps,1)
       thisAmpSet = varAccentAmps(idx,:);
       varAccentStructs(idx,:) = thisAmpSet(accentLevelLocs);
     end
     
   case 'random',
    
    nVarAccentStructs = params.exemplarsPerClass;
    for iVarAcc = 1:nVarAccentStructs
      %the first index of accentLevelAmps should be 1 (max
      %amplitude), so we're only going to vary this by subtracting.
      %The rest are varied by plus or minus the variance value
      varAccentAmps = accentLevelAmps(1) - rand(1).*thisVariance;
      randPosNeg1 = rand(size(accentLevelAmps(2:end))).*2 - 1;
      varAccentAmps = [varAccentAmps (accentLevelAmps(2:end) + randPosNeg1.*thisVariance)];
      varAccentStructs(iVarAcc,:) = varAccentAmps(accentLevelLocs);
      
    end
    
  end
     
     
  nVarAccentStructs = size(varAccentStructs,1);
  for iVarAcc = 1:nVarAccentStructs
    sigLen = round(dur*Fs);
    sig = zeros(sigLen,1);
    
    pulsePeriod = 1./(barFreq*accentStructLen);
    pulsePeriodSamps = round(pulsePeriod*Fs);    
    
    onsetTimesSamps = [1:pulsePeriodSamps:sigLen];
    numOnsets = length(onsetTimesSamps);
    
    accentIndices = mod([0:numOnsets-1],accentStructLen)+1;
    sig(onsetTimesSamps) = varAccentStructs(iVarAcc,accentIndices);
    
    %CONVOLVING WITH GAUSSIAN
    sig = conv(sig,gaussian);
    
    aud_st = init_aud('Fs',Fs,'nchan',1,'wvf',sig);
    fstub = [regexprep(classes{iaccent},'[\s=/]','') 'var' sprintf('%0.4d',iVarAcc)];
    fPath = fullfile(savePath,[fstub '.mat']);
    save(fPath,'aud_st');
    fileList{end+1,1} = fPath;
    
  end
  classList(end+1:end+nVarAccentStructs,1) = repmat(classes(iaccent),nVarAccentStructs,1);
    
  if(params.plotPatterns)
    figure;imagesc(varAccentStructs);colorbar;	title(classes(iaccent));
  end
end

outData = ensemble_init_data_struct;
outData.name = 'exemplars';
outData.type = 'exemplars';
outData.vars = {'audFileList' 'class'};
outDataCols = set_var_col_const(outData.vars);
outData.data{outDataCols.audFileList}(1:length(fileList),1) = fileList;
outData.data{outDataCols.class}(1:length(classList),1) = classList;

return


function outMat = permuteVals(num,nLevels)

  if nLevels == 1
    outMat = [1:num]';
  else
    thisLevel = [];
    for idx = 1:num
      thisLevel(end+1:end+num^(nLevels-1),1) = idx;
    end
    
    outMat = [ thisLevel repmat(permuteVals(num,nLevels-1),num,1)];
  end

return
