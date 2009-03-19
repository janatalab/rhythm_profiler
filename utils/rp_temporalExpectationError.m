function outData = temporalExpectationError(varargin)
%
%
%
%


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
params.removeCurrent.predictSec = 2;
params.removeCurrent.resonType = rp.params.rp.resonatorBank.method;

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
  
  onsetExpectMtx = rp_removeCurrent('resonBankOut',resonBankOut,'Fs',params.Fs,'onsetTimesSamps',onsetTimesSamps,'onsetBorders',onsetBorders,'BList',BList,'AList',AList,'params',params.removeCurrent);
  
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

  figure;
  [distAngles,distRadiuses] = rose_scaled(angle(meanVectorsPerOnset),abs(meanVectorsPerOnset),100);
  
  distEntropy = entropy(distRadiuses);
  distMean = mean(meanVectorsPerOnset);

  axes('position',[.7 .8 .25 .15]);
  set(gca,'visible','off') 
  text(.05,.7,sprintf('Entropy: %.3f',distEntropy));
  text(.05,.5,sprintf('Mean Angle: %.2f',angle(distMean)));
  text(.05,.3,sprintf('Mean Strength: %.2f',abs(distMean)));
  
  
end %for iBank



outData = [];
