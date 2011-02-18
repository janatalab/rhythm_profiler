function outData = get_rp_tempoEstimate(inData, params)
% Returns tempo estimates for a list of given stimulus IDs
%
% out_data = get_rp_tempoEstimate(data_st, params);
%
% Mean periodicity profile (MPP) peak information is loaded from an rp
% analysis structure.  The rp structure is calculated if necessary.
%

% January 20, 2011 Petr Janata

outData = ensemble_init_data_struct;
outData.name = 'tempo_estimate';
outData.type = 'rp_analysis';
copyVars = {'stimulus_id','name','artist','album'};
outData.vars = [copyVars,'tempo'];
outcols = set_var_col_const(outData.vars);

if ~iscell(inData)
  inData = {inData};
end

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimMetaData = inData{findIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);
stimMetaData = ensemble_filter(stimMetaData,params.filt);

nStims = length(stimMetaData.data{stimMetaDataCols.stimulus_id});

% Copy some output data en-masse
for ivar = 1:length(copyVars)
  outData.data(outcols.(copyVars{ivar})) = stimMetaData.data(stimMetaDataCols.(copyVars{ivar}));
end

for iStim = 1:nStims

  thisStimID = ...
      stimMetaData.data{stimMetaDataCols.stimulus_id}(iStim);
  fprintf('Processing Stim %d, ID %d\n',iStim,thisStimID);
  
  params.ipem.ensemble = params.ensemble;
  ipemProc = ipem_proc_series(thisStimID,params.ipem);
  ipemProcCols = set_var_col_const(ipemProc.vars);
  rp = ipemProc.data{ipemProcCols.rp}{1};
  rp = ensemble_datastruct2tree(rp);

  % Find the peak with maximum amplitude
  [dummy,peakIdx]=max(rp.peakInfo.normHeight);
  
  outData.data{outcols.tempo}(iStim) = rp.peakInfo.peakFreq(peakIdx) * 60;
  
end % for iStim
return
