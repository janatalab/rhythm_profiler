function outData = rp_temporalExpectationError(varargin)
% Initializes a rhythm profiler (rp) data struct
% 
% rp = init_rp_struct(varargin)
% 
% INPUTS:
% tag, value pairs:
%      'rp': the rhythm profile to process
%
%      relevant params:
%            params.peakfinder.thresh: threshold for the peak
%                                      finder for finding onsets
%            params.Fs: the sampling rate of the reson filters
%            params.predictCurrentOutput: params struct for predictCurrentOutput.m
%            
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 03/19/2009


for iArg = 1:2:nargin
  switch(varargin{iArg})
   case('rp')
    rp = varargin{iArg+1};
   case('inputSig')
    inputSig = varargin{iArg+1};
  end
end

%if this is an ensemble data struct, convert to tree
if(isfield(rp,'vars') && isfield(rp,'data'))
  rp = ensemble_datastruct2tree(rp);
end

durSamps = size(rp.resonatorOut,3);

params = rp.params.rp;

%onsetDetect.thresh contains the threshold value for detecting
%onset times
try
  params.temporalExpect.onsetDetect.thresh;
catch
  warning('onset detector threshold not set. Setting to 0.05');
  params.temporalExpect.onsetDetect.thresh = 0.05;
end

try
  params.temporalExpect.predictSec;
catch
  warning('reson predictor time not set. Setting to 5 s');
  params.temporalExpect.predictSec = 5;
end

Fs = params.Fs;

nResons = length(rp.resonatorFreqs);

nBanks = size(rp.resonatorOut,1);
nTimeSamps = size(rp.resonatorOut,3);

if(~isempty(params.timeLimSecs))
  timeStartSamps = round(params.timeLimSecs(1)*params.Fs) + 1;
  timeStopSamps = min(round(params.timeLimSecs(2)*params.Fs),nTimeSamps);
else
  timeStartSamps = 1;
  timeStopSamps = nTimeSamps;
end

nFrames = size(rp.resonatorEnergy,2);

for iBank = 1:nBanks
  warning off
  onsetTimesSamps = find_peaks(inputSig(iBank,timeStartSamps:timeStopSamps),params.temporalExpect.onsetDetect);
    
  %Some ANI signals have exhibited large spikes at the beginning of the signal
  %where there probably shouldn't have been one. So, for now, params should be
  %set to throw out the first detected onset for audio files until this problem is solved.
  if(isfield(params.temporalExpect,'throwOutFirstOnset') && params.temporalExpect.throwOutFirstOnset)
    onsetTimesSamps(1) = [];
  end
  
  onsetHeights = peak_heights('signal',inputSig(iBank,:),'peakIdxs',onsetTimesSamps);
  pwParams.calcAt = 'base';
  onsetBorders =  peak_widths('signal',inputSig(iBank,:),'peakIdxs',onsetTimesSamps,'params',pwParams);
  resonBankOut = squeeze(rp.resonatorOut(iBank,:,:)); 
  
  if(size(onsetHeights,1) > size(onsetHeights,2))
    onsetHeights = onsetHeights';
  end
  
  %temporary fix for ensemble_datastruct2tree
  %rp.peakInfo.bandPeakInfo{iBank} = rp.peakInfo.bandPeakInfo{iBank}{1}
  if(iscell(rp.peakInfo.bandPeakInfo{iBank}))
    resonPeakInfo = ensemble_datastruct2tree(rp.peakInfo.bandPeakInfo{iBank}{1});
  else
    resonPeakInfo = rp.peakInfo.bandPeakInfo{iBank};
  end
  
  onsetTimesSampsByBand{iBank} = onsetTimesSamps;
  onsetHeightsByBand{iBank} = onsetHeights;

  if(isempty(resonPeakInfo.peakFreq))
    onsetExpectMtxList{iBank} = [];
    continue;
  end

  lowestReson = resonPeakInfo.peakFreq(1);
  peakIdxs = resonPeakInfo.peakIdxs;

  onsetExpectMtx = rp_predictCurrentOutput('resonBankOut',resonBankOut,'resonFreqs',rp.resonatorFreqs,...
					   'peakIdxs',peakIdxs,'Fs',params.Fs,'onsetTimesSamps',onsetTimesSamps,...
					   'onsetBorders',onsetBorders,'params',params);
  
  onsetExpectMtxList{iBank} = onsetExpectMtx;

end %for iBank

outData = ensemble_init_data_struct;
outData.vars = {'onsetTimesSampsByBand','onsetExpectByBand','onsetHeightByBand'};
outDataCols = set_var_col_const(outData.vars);
outData.data{outDataCols.onsetTimesSampsByBand} = onsetTimesSampsByBand;
outData.data{outDataCols.onsetHeightByBand} = onsetHeightsByBand;
outData.data{outDataCols.onsetExpectByBand} = onsetExpectMtxList;
