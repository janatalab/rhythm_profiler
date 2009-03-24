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
params.predictCurrentOutput.predictSec = 2;
params.predictCurrentOutput.resonType = rp.params.rp.resonatorBank.method;

plotFileStub = params.plotFileStub;

delete([plotFileStub '_bank*']);

nResons = length(rp.resonatorFreqs);

nBanks = size(rp.resonatorOut,1);
nTimeSamps = size(rp.resonatorOut,3);

nFrames = size(rp.resonatorEnergy,2);

for iBank = 1:nBanks
  warning off
  onsetTimesSamps = find_peaks(rp.denv(iBank,:),params.peakfinder);
  onsetHeights = peak_heights('signal',rp.denv(iBank,:),'peakIdxs',onsetTimesSamps);
  onsetBorders =  peak_widths('signal',rp.denv(iBank,:),'peakIdxs',onsetTimesSamps);
  resonBankOut = squeeze(rp.resonatorOut(iBank,:,:));
  
  onsetExpectMtx = rp_predictCurrentOutput('resonBankOut',resonBankOut,'Fs',params.Fs,'onsetTimesSamps',onsetTimesSamps,'onsetBorders',onsetBorders,'BList',BList,'AList',AList,'params',params.predictCurrentOutput);
  
  %using the square of the APS at the onset times as relative
  %strengths of the resonators
  onsetExpectStrengths = rp.resonatorEnergy(:,onsetTimesSamps).^2;
  
  %scaling the onset expectation matrix by the strengths and normalizing
  onsetExpectMtx = onsetExpectMtx .* onsetExpectStrengths;
  onsetExpectMtx = onsetExpectMtx ./ max(abs(onsetExpectMtx(:)));
  
  %take the mean of expectation resonators at each onset
  meanVectorsPerOnset(iBank,:) = mean(onsetExpectMtx,1);
 
  %further scale that mean by the onset height. Low onsets will
  %contribute much less to the degree of expectancy violation or agreement
  meanVectorsPerOnset(iBank,:) = meanVectorsPerOnset(iBank,:) .* onsetHeights';
  
  %OLD CODE. COMMENTED OUT FOR NOW
  %complexOnsets = complex(onsetHeights,zeros(size(onsetHeights)))';
  %diffVectors = onsetHeights' - meanVectorsPerOnset;

  [distAngles,distRadii,tout,rout] = rose_scaled(angle(meanVectorsPerOnset),abs(meanVectorsPerOnset),100,[],0);
  
  distEntropy = entropy(distRadii);
  distMean = mean(meanVectorsPerOnset);

  %{
  axes('position',[.7 .8 .25 .15]);
  set(gca,'visible','off') 
  text(.05,.7,sprintf('Entropy: %.3f',distEntropy));
  text(.05,.5,sprintf('Mean Angle: %.2f',angle(distMean)));
  text(.05,.3,sprintf('Mean Strength: %.2f',abs(distMean)));
  %}
  
end %for iBank


outData = ensemble_init_data_struct;
outData.vars = {'distAngles','distRadii','distEntropy','distMean','thetaDistPlotInfo','radDistPlotInfo'};
outDataCols = set_var_col_const(outData.vars);
outData.data{outDataCols.distAngles} = distAngles;
outData.data{outDataCols.distRadii} = distRadii;
outData.data{outDataCols.distEntropy} = distEntropy;
outData.data{outDataCols.distMean} = distMean;
outData.data{outDataCols.thetaDistPlotInfo} = tout;
outData.data{outDataCols.radDistPlotInfo} = rout;
