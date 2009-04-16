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
   case('params')
    params = varargin{iArg+1};
  end
end

%if this is an ensemble data struct, convert to tree
if(isfield(rp,'vars') && isfield(rp,'data'))
  rp = ensemble_datastruct2tree(rp);
end

params.peakfinder.thresh = 0.001;
params.Fs = 100;
params.plotFileStub = '/data2/rhythm/rhythm_profiler/plots/beat_variability/angle_histograms';
params.predictCurrentOutput.predictSec = 5;
params.predictCurrentOutput.resonType = rp.params.rp.resonatorBank.method;

plotFileStub = params.plotFileStub;

delete([plotFileStub '_bank*']);

nResons = length(rp.resonatorFreqs);

nBanks = size(rp.resonatorOut,1);
nTimeSamps = size(rp.resonatorOut,3);

nFrames = size(rp.resonatorEnergy,2);
onsetTimesAll = [];

for iBank = 1:nBanks
  warning off
  onsetTimesSamps = find_peaks(rp.sumDenv(iBank,:),params.peakfinder);
  onsetHeights = peak_heights('signal',rp.sumDenv(iBank,:),'peakIdxs',onsetTimesSamps);
  onsetBorders =  peak_widths('signal',rp.sumDenv(iBank,:),'peakIdxs',onsetTimesSamps);
  resonBankOut = squeeze(rp.resonatorOut(iBank,:,:)); 
  
  if(size(onsetHeights,1) > size(onsetHeights,2))
    onsetHeights = onsetHeights';
  end
  
  %figure(1);plot(rp.denv(iBank,:));set(gca,'xlim',[500 800]);
  
  onsetExpectMtx = rp_predictCurrentOutput('resonBankOut',resonBankOut,'resonFreqs',rp.resonatorFreqs,'Fs',params.Fs,'onsetTimesSamps',onsetTimesSamps,'onsetBorders',onsetBorders,'BList',BList,'AList',AList,'params',params.predictCurrentOutput);
  
  %using the square of the APS at the onset times as relative
  %strengths of the resonators
  %onsetExpectStrengths = rp.resonatorEnergy(:,onsetTimesSamps).^8;

  %throwing out all but the most salient information
  %normOnsetExpectStrengths = onsetExpectStrengths ./ max(abs(onsetExpectStrengths(:)));
  %onsetExpectStrengths(normOnsetExpectStrengths < 0.1) = 0;
  
  %scaling the onset expectation matrix by the strengths and normalizing
  %onsetExpectStrengths = abs(onsetExpectMtx).^4;
  %onsetExpectMtx = onsetExpectMtx .* onsetExpectStrengths;
  
  %further scale by the onset heights
  %onsetExpectMtx = onsetExpectMtx .* repmat(onsetHeights,nResons,1);
  
  onsetExpectMtxList{iBank} = onsetExpectMtx;

  onsetTimeList{iBank} = onsetTimesSamps;
  onsetTimesAll = union(onsetTimesSamps,onsetTimesAll);
  
  %take the mean of expectation resonators at each onset
  %meanVectorsPerOnset(iBank,:) = mean(onsetExpectMtx,1);
 
  %further scale that mean by the onset height. Low onsets will
  %contribute much less to the degree of expectancy violation or agreement
  %meanVectorsPerOnset(iBank,:) = meanVectorsPerOnset(iBank,:) .* onsetHeights';

  %angleCenters = [0:(2*pi)/100:2*pi];
  
  %[distAngles,distRadii,tout,rout] = rose_scaled(angle(meanVectorsPerOnset),abs(meanVectorsPerOnset),100,0,[],0);
  
  %distEntropy = entropy(distRadii);
  %distMean = mean(meanVectorsPerOnset);

end %for iBank

%build a 3d matrix that contains the onset info of all banks
onsetExpectMtxAllBanks = zeros(nBanks,nResons,length(onsetTimesAll));
for iBank = 1:nBanks
  [dummy,onsetIdx] = intersect(onsetTimesAll,onsetTimeList{iBank}); 
  onsetExpectMtxAllBanks(iBank,1:nResons,onsetIdx) = onsetExpectMtxList{iBank};
end
 
onsetExpectMtxAllBanks = squeeze(onsetExpectMtxAllBanks);

%normalize expectation matrix
onsetExpectMtxAllBanks = onsetExpectMtxAllBanks ./ max(abs(onsetExpectMtxAllBanks(:)));


outData = ensemble_init_data_struct;
outData.vars = {'onsetExpectMtx','onsetTimesSamps','distAngles','distRadii','distEntropy','distMean','thetaDistPlotInfo','radDistPlotInfo'};
outDataCols = set_var_col_const(outData.vars);
outData.data{outDataCols.onsetExpectMtx} = onsetExpectMtxAllBanks;
outData.data{outDataCols.onsetTimesSamps} = onsetTimesAll;
%outData.data{outDataCols.distAngles} = distAngles;
%outData.data{outDataCols.distRadii} = distRadii;
%outData.data{outDataCols.distEntropy} = distEntropy;
%outData.data{outDataCols.distMean} = distMean;
%outData.data{outDataCols.thetaDistPlotInfo} = tout;
%outData.data{outDataCols.radDistPlotInfo} = rout;
