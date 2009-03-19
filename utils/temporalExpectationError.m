function outData = temporalExpectationError(inData,params)
%
%
%
%

params.scalingPower = 1;
params.maskThreshold = 0.4;
params.frameSizeSecs = 2;
params.Fs = 100;
params.onsetVariabilityRangeMs = [-500 500];
params.peakfinder.thresh = 0;
params.plotFileStub = '/data2/rhythm/rhythm_profiler/plots/beat_variability/angle_histograms';

plotFileStub = params.plotFileStub;

delete([plotFileStub '_bank*']);

rp = ensemble_datastruct2tree(inData);
nResons = length(rp.resonatorFreqs);
scalingPower = params.scalingPower;
maskThreshold = params.maskThreshold;
frameSizeSamps = params.frameSizeSecs * params.Fs;
onsetVariabilityRangeSamps = round(params.onsetVariabilityRangeMs ./1000 .* params.Fs);

sharpenedAPS = ( rp.resonatorEnergy/max(rp.resonatorEnergy(:)) ).^scalingPower;

nBanks = size(rp.resonatorOut,1);
nTimeSamps = size(rp.resonatorOut,3);

nFrames = size(rp.resonatorEnergy,2);
disp('Calculating normalized energy on a frame by frame basis...');
for iFrame = 1:nFrames
  frameStart = max(1,iFrame - frameSizeSamps + 1);
  frameSamps = [frameStart:iFrame];
  frameEnergy = mean(rp.resonatorEnergy(:,frameSamps).^2,2);
  maxFrameEnergy = max(frameEnergy);
  if(maxFrameEnergy ~= 0)
    frameEnergy = frameEnergy./maxFrameEnergy;
  end
  frameEnergyByReson(:,iFrame) = frameEnergy;

end

for iBank = 1:nBanks
  deltaPhasesThisBand = [];
  deltaStrengthsThisBand = [];
  sharpResonBankOut = squeeze(rp.resonatorOut(iBank,:,:)) ...
      .* frameEnergyByReson;

  %{
  %ATTEMPTING TO SHARPEN RESON FILTERS BY NORMALIZING FRAME BY
  %FRAME. THIS IS NOT USED FOR NOW
  for iFrame = 1:nFrames
    frameStart = max(1,iFrame - frameSizeSamps + 1);
    frameSamps = [frameStart:iFrame];
    maxFrameVal(iFrame) = max(max(rp.resonatorOut(iBank,:,frameSamps)));
  end
  %for any maxFrameVal == 0, just set this to 1 to avoid dividing
  %by 0. This doesn't affect normalization since all reson outputs
  %at this frame are 0 anyway.
  maxFrameVal(maxFrameVal == 0) = 1;
  sharpResonBankOut2 = squeeze(rp.resonatorOut(iBank,:,:)) ./ ...
      repmat(maxFrameVal,length(rp.resonatorFreqs),1) .* frameEnergyByReson;
  %}
  
  normSharpResonBankOut = sharpResonBankOut ./ max(sharpResonBankOut(:));
  expectationMask = normSharpResonBankOut > maskThreshold;  
  onsetTimesSamps = find_peaks(rp.denv(iBank,:),params.peakfinder);
  %onsetHeights = peak_heights('signal',rp.denv(iBank,:),'peakIdxs',onsetTimesSamps);
  
  nOnsets = length(onsetTimesSamps);
  for iOnset = 1:nOnsets
    
    onsetExpectTimeRange = onsetTimesSamps(iOnset) + onsetVariabilityRangeSamps;
    onsetExpectTimeRange(1) = max(1,onsetExpectTimeRange(1));
    onsetExpectTimeRange(2) = min(size(expectationMask,2),onsetExpectTimeRange(2));
    onsetExpectTimeVector = [onsetExpectTimeRange(1):onsetExpectTimeRange(2)];
    [freqIdxs,onsetExpectTimes] = find(expectationMask(:,onsetExpectTimeVector));
    onsetExpectResonFreqs = rp.resonatorFreqs(freqIdxs)';
    onsetExpectTimes = onsetExpectTimes + onsetExpectTimeRange(1) - 1;
   
    deltaTimes = onsetExpectTimes - onsetTimesSamps(iOnset);
    %deltaStrengths = repmat(onsetHeights(iOnset),size(deltaTimes));
    deltaTimesSecs = deltaTimes ./ params.Fs;
    deltaPhases = deltaTimesSecs .* onsetExpectResonFreqs ./ (2*pi);
    deltaPhasesThisBand = [deltaPhasesThisBand ; deltaPhases];
    %deltaStrengthsThisBand= [deltaStrengthsThisBand ; deltaStrengths];
    
    if(mod(iOnset - 1,10) == 0)
      figure;
      set(gcf,'paperposition',[0.5 0.5 8 10],'position',[100 100 800 1000]);
    end
    subplot(5,2,mod(iOnset-1,10)+1);
    axis square;
    if(~isempty(deltaPhases))
      rose(deltaPhases,60);
      %rose_scaled(deltaPhases,deltaStrengths,60);
    else
     text(.5,.5,'Empty');
    end
   
    if( (mod(iOnset,10) == 0) || (iOnset == nOnsets) )
      plotFilePath = [plotFileStub sprintf('_bank%d.ps',iBank)];
      print('-dpsc','-append',plotFilePath);
      close(gcf);
    end
     
    %histCenters = [onsetVariabilityRangeSamps(1):onsetVariabilityRangeSamps(2)];
    %histDeltaTimes = hist(deltaTimes,histCenters);
    %{
    if( (~all(histDeltaTimes) == 0) )
      %just using highest hist value in delta time for now. Probably want a better measure
      peakDeltaIdx = find(histDeltaTimes == max(histDeltaTimes));
      if (length(peakDeltaIdx) > 1)
	%if there is more than one peak delta, use the one that is
        %closest to 0
	warning('found more than one delta');
	minPeakDelta = find(histCenters(peakDeltaIdx) == min(histCenters(peakDeltaIdx)));
	peakDeltaIdx = peakDeltaIdx(minPeakDelta);
      end
      peakDeltaTimes(iOnset) = histCenters(peakDeltaIdx);
    else
      peakDeltaTimes(iOnset) = 0;
    end
    %}
  end
  
  %figure;rose_scaled(deltaPhasesThisBand,deltaStrengthsThisBand,60);
  
end %for iBank



outData = [];
