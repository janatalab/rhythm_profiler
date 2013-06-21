function outData = get_rp_tempoEstimate(inData, params)
% Returns tempo estimates for a list of given stimulus IDs
%
% out_data = get_rp_tempoEstimate(data_st, params);
%
% Mean periodicity profile (MPP) peak information is loaded from an rp
% analysis structure.  The rp structure is calculated if necessary.
%

% January 20, 2011 Petr Janata
% 13May2013 PJ - made filtering with params.filt optional
% May2013 PJ - added tempo estimate confidence calculation

outData = ensemble_init_data_struct;
outData.name = 'tempo_estimate';
outData.type = 'rp_analysis';
copyVars = {'stimulus_id','name','artist','album'};
outData.vars = [copyVars,'tempo','tempo_confidence'];
outcols = set_var_col_const(outData.vars);

if ~iscell(inData)
  inData = {inData};
end

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimMetaData = inData{findIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);

if isfield(params, 'filt')
  stimMetaData = ensemble_filter(stimMetaData,params.filt);
end

nStims = length(stimMetaData.data{stimMetaDataCols.stimulus_id});

% Copy some output data en-masse
for ivar = 1:length(copyVars)
  outData.data(outcols.(copyVars{ivar})) = stimMetaData.data(stimMetaDataCols.(copyVars{ivar}));
end

if ~isfield(params,'jlmt') || ~isfield(params.jlmt,'ensemble')
  params.jlmt.ensemble = params.ensemble;
end

if ~isfield(params.jlmt, 'mysql') && isfield(params, 'mysql')
  params.jlmt.mysql = params.mysql;
end

% Check whether confidence parameters have been set
if isfield(params, 'tempo') && isfield(params.tempo, 'confidence')
  try
    propPeakHeight = params.tempo.confidence.propPeakHeight;
  catch
    propPeakHeight = 1; % don't estimate confidence by default
  end
end

% Initialize variables
stimIDs = stimMetaData.data{stimMetaDataCols.stimulus_id};
tempo = nan(nStims,1); % use this temporary variable to make parfor happy
confidence = nan(nStims,1);

parfor iStim = 1:nStims
  try

    thisStimID = stimIDs(iStim);
    fprintf('Processing Stim %d, ID %d\n',iStim,thisStimID);
    
    jlmtProc = jlmt_proc_series(thisStimID,params.jlmt);
    jlmtProcCols = set_var_col_const(jlmtProc.vars);
    rp = jlmtProc.data{jlmtProcCols.rp}{1};
    rp = ensemble_datastruct2tree(rp);
    
    % Find the peak with maximum amplitude
    [maxHeight,peakIdx] = max(rp.peakInfo.normHeight);
    
    % calculate tempo from the max amplitude peak
    tempo(iStim) = rp.peakInfo.peakFreq(peakIdx) * 60;
    
    % Try to provide a confidence estimate
    % One way to conceptualize confidence is in terms of how many other
    % peaks there are that are close in amplitude to the overall maximum,
    % e.g. fall within some percentage of the overall height.
    otherPeakIdxs = rp.peakInfo.normHeight >= maxHeight * propPeakHeight;
    confidence(iStim) = 1/sum(otherPeakIdxs);
    
    % Another approach to tempo identification could be to use a
    % probability weighting function that would discount tempi that are too
    % slow or too fast
    
  catch ME
    rethrow(ME)
  end
  
end % for iStim
outData.data{outcols.tempo} = tempo;
outData.data{outcols.tempo_confidence} = confidence;

return
