function outData = get_stim_summaryMeasurements(inData,params)
%
% Was get_stim_meanRhythmProfile.m. Returns summary measurements for each stim
% (e.g. npeaks, complex_simple, mean-var-Coherence, etc.)
%
% If any additional summary measurements are desired, they may be added here
% instead of in a post-processing script.
%
% 2/23/10 - renamed function and added timing expectancy calculations
  
ensemble_globals;

  
meanResEnergy = ensemble_init_data_struct;
meanResEnergy.vars = {'stimulus_id','artist','song_name','stimulus_category', ...
		    'MPP','stdPP','resonFreqs','npeaks','complex_simple', ...
		    'peakConcentration', ...
		    'mmCoh','mvCoh','vmCoh','vvCoh', ...
		    'mmPred','mvPred','vmPred','vvPred', ...
		    'mmTD','mvTD','vmTD','vvTD',...
		    'mmLogFul','mvLogFul','vmLogFul','vvLogFul','mmDenv', ...
		    'sigRMS','maxAmp'};

mrCols = set_var_col_const(meanResEnergy.vars);

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimMetaData = inData{findIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);
stimMetaData = ensemble_filter(stimMetaData,params.stims.filt);

clear searchCrit;
searchCrit.type = 'stimulus_x_attribute_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimAttMetaData = inData{findIdx};
stimAttMetaDataCols = set_var_col_const(stimAttMetaData.vars);
stimAttMetaData = ensemble_filter(stimAttMetaData,params.stimAttributes.filt);


nStims = length(stimMetaData.data{stimMetaDataCols.stimulus_id});

for iStim = 1:nStims

  thisStimID = ...
      stimMetaData.data{stimMetaDataCols.stimulus_id}(iStim);

  fprintf('Processing Stim %d, ID %d\n',iStim,thisStimID);
  
  %calculate simple RMS of stim signal
  %to make sure this isn't affecting stim ratings
  stimSig = read_audio_stim(thisStimID,[],1);
  rmsStimSig = sqrt(mean(stimSig.^2));
  
  stimAttIdx = find(stimAttMetaData.data{stimAttMetaDataCols.stimulus_id} == thisStimID);
  thisStimCat = stimAttMetaData.data{stimAttMetaDataCols.name}{stimAttIdx};
  
  thisLocation = stimMetaData.data{stimMetaDataCols.location}{iStim};
  [path,fstub,ext] = fileparts(fullfile(stimulus_ipem_analysis_root,thisLocation));
  
  rpPath = fullfile(path,fstub,'rp');
  
  params.ipem.ensemble = params.ensemble;
  ipemProc = ipem_proc_series(thisStimID,params.ipem);
  ipemProcCols = set_var_col_const(ipemProc.vars);
  rp = ipemProc.data{ipemProcCols.rp}{1};
  rp = ensemble_datastruct2tree(rp);

  artist = stimMetaData.data{stimMetaDataCols.artist}{iStim};
  song_name = stimMetaData.data{stimMetaDataCols.name}{iStim};
  
  meanResEnergy.data{mrCols.stimulus_id}(iStim,1) = thisStimID;
  meanResEnergy.data{mrCols.artist}{iStim,1} = artist;
  meanResEnergy.data{mrCols.song_name}{iStim,1} = song_name;
  meanResEnergy.data{mrCols.stimulus_category}{iStim,1} = thisStimCat;
  meanResEnergy.data{mrCols.MPP}{iStim,1} = rp.meanResonatorEnergy;
  meanResEnergy.data{mrCols.stdPP}{iStim,1} = rp.stdResonatorEnergy;
  meanResEnergy.data{mrCols.resonFreqs}{iStim,1} = rp.resonatorFreqs;

  if isfield(rp,'interpMPPStruct') && ~isempty(rp.interpMPPStruct)
    mppPeaks = rp.interpMPPStruct.peakInfo.peakFreq;
  else
    mppPeaks = rp.peakInfo.peakFreq;
  end
  
  nPeaks = length(mppPeaks);
  meanResEnergy.data{mrCols.npeaks}(iStim,1) = nPeaks;
  meanResEnergy.data{mrCols.complex_simple}(iStim,1) = rp_binRatioComplexity(rp);

  peakConcentration = sum(rp.peakInfo.normHeight) ./ nPeaks;
  
  meanResEnergy.data{mrCols.peakConcentration} = peakConcentration;
  
  
  %get mean denvAtOnsets
  if isfield(rp,'onsetInfo') && ~isempty(rp.onsetInfo)
    nBands = size(rp.sumDenv,1);
    for iBand = 1:nBands
      denvThisBand = rp.sumDenv(iBand,:);
      onsetTimesThisBand = rp.onsetInfo.onsetTimesSampsByBand{iBand};
      denvAtOnsets = denvThisBand(onsetTimesThisBand);
      meanDenvByBand(iBand) = mean(denvAtOnsets);
      
    end
    meanResEnergy.data{mrCols.mmDenv}(iStim,1) = mean(meanDenvByBand);
    meanResEnergy.data{mrCols.sigRMS}(iStim,1) = rmsStimSig;
    meanResEnergy.data{mrCols.maxAmp}(iStim,1) = max(stimSig);
  end
  
  if isfield(rp,'coherence') && ~isempty(rp.coherence)
    summaryParams.throwOutFirstIdx = 0;
    [meanResEnergy.data{mrCols.mmCoh}(iStim,1),...
      meanResEnergy.data{mrCols.mvCoh}(iStim,1),...
      meanResEnergy.data{mrCols.vmCoh}(iStim,1),...
      meanResEnergy.data{mrCols.vvCoh}(iStim,1)] = rp_summaryTempExpect(rp.coherence.cohPerPeakPerBand,summaryParams);
  end
  
  if isfield(rp,'vmExpect') && ~isempty(rp.vmExpect)
    summaryParams.throwOutFirstIdx = 1;
    [meanResEnergy.data{mrCols.mmPred}(iStim,1),...
      meanResEnergy.data{mrCols.mvPred}(iStim,1),...
      meanResEnergy.data{mrCols.vmPred}(iStim,1),...
      meanResEnergy.data{mrCols.vvPred}(iStim,1)] = rp_summaryTempExpect(rp.vmExpect.vmPredictionPerOnset,summaryParams);
    
    
    summaryParams.throwOutFirstIdx = 1;
    [meanResEnergy.data{mrCols.mmTD}(iStim,1),...
      meanResEnergy.data{mrCols.mvTD}(iStim,1),...
      meanResEnergy.data{mrCols.vmTD}(iStim,1),...
      meanResEnergy.data{mrCols.vvTD}(iStim,1)] = rp_summaryTempExpect(rp.vmExpect.vmTimingDev,summaryParams);
    
    summaryParams.throwOutFirstIdx = 1;
    [meanResEnergy.data{mrCols.mmLogFul}(iStim,1),...
      meanResEnergy.data{mrCols.mvLogFul}(iStim,1),...
      meanResEnergy.data{mrCols.vmLogFul}(iStim,1),...
      meanResEnergy.data{mrCols.vvLogFul}(iStim,1)] = rp_summaryTempExpect(rp.vmExpect.vmLogFulfillPerOnset,summaryParams);
  end
end

outData = meanResEnergy;

return





