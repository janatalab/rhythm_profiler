function outData = rp_temporalExpectationError(varargin)
% Initializes a rhythm profiler (rp) data struct
% 
% rp = init_rp_struct(varargin)
% 
% INPUTS:
% tag, value pairs:
%      'rp': the rhythm profile to process
%   'BList': A Cell array of vectors, where each vector contains the
%            numerator coefficients of a reson filter
%   'AList': A Cell array of vectors, where each vector contains the
%            denominator coefficients of a reson filter
%  'params': params struct for this function
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
   case('BList')
    BList = varargin{iArg+1};
   case('AList')
    AList = varargin{iArg+1};
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

nFrames = size(rp.resonatorEnergy,2);
onsetTimesAll = [];

for iBank = 1:nBanks
  warning off
  onsetTimesSamps = find_peaks(inputSig(iBank,:),params.temporalExpect.onsetDetect.thresh);
  
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
  rmsFrameSize = 1./lowestReson;
  params.predictCurrentOutput.rmsFrameSize = rmsFrameSize;
  onsetExpectMtx = rp_predictCurrentOutput('resonBankOut',resonBankOut,'resonFreqs',rp.resonatorFreqs,'peakIdxs',peakIdxs,'Fs',params.Fs,'onsetTimesSamps',onsetTimesSamps,'onsetBorders',onsetBorders,'BList',BList,'AList',AList,'params',params);
 
  onsetExpectMtxList{iBank} = onsetExpectMtx;

end %for iBank

outData = ensemble_init_data_struct;
outData.vars = {'onsetTimesSampsByBand','onsetExpectByBand','onsetHeightByBand'};
outDataCols = set_var_col_const(outData.vars);
outData.data{outDataCols.onsetTimesSampsByBand} = onsetTimesSampsByBand;
outData.data{outDataCols.onsetHeightByBand} = onsetHeightsByBand;
outData.data{outDataCols.onsetExpectByBand} = onsetExpectMtxList;
