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

if ~isfield(params,'jlmt') || ~isfield(params.jlmt,'ensemble')
  params.jlmt.ensemble = params.ensemble;
end

tempo = nan(nStims,1); % use this temporary variable to make parfor happy
parfor iStim = 1:nStims

  try

  thisStimID = ...
      stimMetaData.data{stimMetaDataCols.stimulus_id}(iStim);
  fprintf('Processing Stim %d, ID %d\n',iStim,thisStimID);

  jlmtProc = jlmt_proc_series(thisStimID,params.jlmt);
  jlmtProcCols = set_var_col_const(jlmtProc.vars);
  rp = jlmtProc.data{jlmtProcCols.rp}{1};
  rp = ensemble_datastruct2tree(rp);

  % Find the peak with maximum amplitude
  [dummy,peakIdx]=max(rp.peakInfo.normHeight);
  
  % calculate tempo from the max amplitude peak
  tempo(iStim) = rp.peakInfo.peakFreq(peakIdx) * 60;

  end
  
end % for iStim
outData.data{outcols.tempo} = tempo;

return
