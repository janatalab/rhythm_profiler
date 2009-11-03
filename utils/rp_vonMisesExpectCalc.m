function outData = rp_vonMisesExpectCalc(varargin)
% Calculates an expectation error based on von Mises distributions across metric levels
% 
% outData = rp_vonMisesExpectCalc(inData,params)
% 
% INPUTS (tag/value pairs):
%         rp - a rhythm profiler struct
%   inputSig - the input signal to the resonator model (denv, sumDenv, or any
%              other signal)
%
%     RELEVANT PARAMS:
%              params.vmExpect.distResolution: The bin size of the
%                 von Mises distribution
%
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 04/23/2009

%Debug params
DO_DEBUG = 0;
NPLOTS = 5;
  
for iarg = 1:2:nargin
  switch varargin{iarg}
   case 'rp'
    rp = varargin{iarg+1};
   case 'inputSig'
    inputSig = varargin{iarg+1};
  end
end

rpCols = set_var_col_const(rp.vars);
params = rp.data{rpCols.params}.rp;

try
  params.vmExpect.distResolution = 50;
catch
  warning('von Mises distribution resolution not set. Setting to 50.');
  params.vmExpect.distResolution = 50;
end

distResolution = params.vmExpect.distResolution;
angleDistVector = [-pi:pi/distResolution:pi];
angleZeroIdx = find(angleDistVector == 0);

if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

expectErrorStruct = rp.expectationError;

peakFinderParams =  params.resonatorBank.peakFinder;
resonFreqs = rp.resonatorFreqs;
nResons = length(resonFreqs);
nBands = length(expectErrorStruct.onsetTimesSampsByBand);

for iBand = 1:nBands

  %we should probably be sending onsetExpectMtx as a cell array of
  %matrices instead of a big 3D matrix. This is why we need to
  %match actual onset times for this band to the 3D matrix.
  onsetTimesThisBand = expectErrorStruct.onsetTimesSampsByBand{iBand};

  if(length(onsetTimesThisBand) <=1)
    vmPredictionPerOnset{iBand} = [];
    vmViolationPerOnset{iBand} = [];
    vmAreaPerPeakList{iBand} = [];
    vmProportionsPerPeakList{iBand} = [];
    vmPeakFreqs{iBand} = [];
    vmK{iBand} = [];
    vmTimingDev{iBand} = [];
    vmDistPerPeakPerOnset = [];
    continue;
  end
     
  nOnsets = length(onsetTimesThisBand);
  
  %obtain the denv magnitudes at onset times
  denvAtOnsets = squeeze(inputSig(iBand,onsetTimesThisBand));
  denvThisBand = inputSig(iBand,:);

  
  %getting band peak info. This should have really been done from
  %rhythm_profiler
  %the following two lines retrieve info already contained in rp struct. Delete
  %after verifying that this is not needed
  %mppThisBand = mean(squeeze(rp.resonatorBandEnergy(iBand,:,:)),2);
  %bandPeakInfo = get_resonPeakInfo(mppThisBand,resonFreqs,peakFinderParams);
  bandPeakInfo = rp.peakInfo.bandPeakInfo{iBand};
  
  bandPeakFreqs = bandPeakInfo.peakFreq;
  bandPeakIdxs = bandPeakInfo.peakIdxs;
  
  lowestResonPeriodSecs = 1./resonFreqs(bandPeakIdxs(1));
  lowestResonPeriodSamps = lowestResonPeriodSecs .* rp.Fs;
  denvEnergy = [];
  
  %normalizing by RMS here
  rmsResonThisBand = sqrt(mean(squeeze(rp.resonatorOut(iBand,bandPeakIdxs,:)).^2,2));
  meanRMSThisBand = mean(rmsResonThisBand);
  onsetExpectByBand = expectErrorStruct.onsetExpectByBand{iBand};
  onsetExpectByBand = onsetExpectByBand ./meanRMSThisBand;

  %calculating denvEnergy across time window range of
  %onsets. We should probably do this from the beginning, but we're
  %avoiding the spike mentioned above
  %timeLimVec = onsetTimesThisBand(1):onsetTimesThisBand(end);
  denvEnergy = sqrt(mean(denvThisBand.^2));

  adjDenvAtOnsets = denvAtOnsets ./ denvEnergy;
    
  for iOnset = 1:nOnsets
    
    thisComplexResonOut = onsetExpectByBand(:,iOnset);
    thisComplexResonMags = abs(thisComplexResonOut);
    thisComplexResonPhases = angle(thisComplexResonOut);
    
    peakFreqs = bandPeakInfo.peakFreq;
    peakWidths = bandPeakInfo.baseWidths/4;
    peakIdxs = bandPeakInfo.peakIdxs;
    peakHeights = bandPeakInfo.normHeight;
    peakPhases = angle(thisComplexResonOut(peakIdxs))';
    nPeaks = length(peakIdxs);

    clear variance vmDistPerPeak vmAreaPerPeak vmProbPerPeak vmAdjProbPerPeak vmAdjProbPerPeakTest metricLevel pwProportion;
    k = [];
    timingDev = [];
    for iPeak = 1:nPeaks
	
      pwProportion(iPeak) = peakWidths(iPeak)./ peakFreqs(iPeak)./peakHeights(iPeak);
      variance(iPeak) = pwProportion(iPeak);

      k(iPeak)  = 1./(variance(iPeak));
      vmDistPerPeak(iPeak,:) =  von_mises_pdf(angleDistVector,0,k(iPeak));

      diffAngle = peakPhases(iPeak) - angleDistVector;
      evalAngleIdx = find(abs(diffAngle) == min(abs(diffAngle)));
      
      evalAngleIdxPerPeak(iPeak) = evalAngleIdx;
      
      weight = thisComplexResonMags(peakIdxs(iPeak))./nPeaks;
      
      vmProbPerPeak(iPeak) = vmDistPerPeak(iPeak,evalAngleIdx).*weight;

      %find the indices to evaluate for the area of the von mises
      %dist (timing dev calc)
      if(angleZeroIdx >= evalAngleIdx)
	areaIdxs = evalAngleIdx:angleZeroIdx;
      else
	areaIdxs = angleZeroIdx:evalAngleIdx;
      end
      
      vmAreaPerPeak(iPeak) = sum(vmDistPerPeak(iPeak,areaIdxs).*...
				 weight.*(pi/distResolution));
    
      
      if(DO_DEBUG)
	
	if(((mod(iOnset,NPLOTS) == 0) || iOnset == 1) && (iPeak == 1))
	  figure;
	  set(gcf,'position',[100 100 800 1000],'paperposition',[0.25 0.25 8.0 10.0]);
	  titleAx = axes('position',[0 0.95 1 0.05],'visible','off');
	  text(0.5,0.5,params.temporalExpect.debugPlotTitle,'fontsize',16,'fontweight','bold','horizontalalignment','center');
	
	  if(iOnset == 1)
	    subplot(NPLOTS,1,1);
	    plot(rp.mppByBand{iBand});
	  end
	end
	
	distCMap = hsv(nPeaks);
	
	plotIdx = mod(iOnset,NPLOTS) + 1;
	plotAxH = subplot(NPLOTS,1,plotIdx);

	centerIdx = round(length(angleDistVector) ./ 2);
		
	if(iPeak == 1)
	  plot([0 0],[0 1],'k');
	  hold on;
	  clear plotHandles;
	end
	
	%recenter the distribution so that onset time is in center
	idxOffset = evalAngleIdx - centerIdx;
	idxList = [1:length(angleDistVector)] + idxOffset;
	%all idx values that are out of range are set to wrap around
	idxList = mod(idxList-1,length(angleDistVector)) + 1;
	plotHandles(iPeak) = plot(angleDistVector,vmDistPerPeak(iPeak,idxList).*weight,'color',distCMap(iPeak,:));
	
	if(iPeak == nPeaks)
	  legendLabels = strsplit(sprintf('peak %d,',[1:nPeaks]),',');
	  legend(gca,plotHandles,legendLabels);
	  set(gca,'xtick',[-pi -pi/2 0 pi/2 pi],'xticklabel',{'-pi','-pi/2','0','pi/2','pi'});
	  set(gca,'xlim',[-pi pi]);
	  yLimVals = get(gca,'ylim');
	  text(-pi+0.1,yLimVals(2)*.8,params.temporalExpect.debugLabels{iOnset});
	  axpos = get(gca,'position');
	  axRightPos = axpos(1) + axpos(3);
	  labelAx = axes('position',[axRightPos axpos(2) (1-axRightPos) axpos(4)],'visible','off');
	  text(0.5,0.5,sprintf('%.2f',sum(vmAreaPerPeak)),'horizontalalignment','center','fontsize',14);
	  
	end
	
	
      end
      
    end %for iPeak
    
    vmPredictionPerOnset{iBand}(iOnset) = sum(vmProbPerPeak);
    vmViolationPerOnset{iBand}(iOnset) = abs(adjDenvAtOnsets(iOnset) - sum(vmProbPerPeak));
    vmAreaPerPeakList{iBand,iOnset} = vmAreaPerPeak;
    vmProportionsPerPeakList{iBand,iOnset} = variance;
    vmK{iBand,iOnset} = k;
    vmTimingDev{iBand}(iOnset) = sum(vmAreaPerPeak);
    vmDistPerPeakPerOnset{iOnset} = vmDistPerPeak;
    

    if(DO_DEBUG && (plotIdx == NPLOTS) && (iOnset < nOnsets))
      plotFPath = fullfile(params.temporalExpect.debugPlotFPath,params.temporalExpect.debugPlotFname);
      print(plotFPath,'-dpsc','-append');
      close(gcf);
    end
    
  end %for iOnset 
  
  vmPeakFreqs{iBand} = peakFreqs;
  
  
  if(DO_DEBUG)
    %debug routines that need variables that accumulate across onsets can
    %go here
    plotFPath = fullfile(params.temporalExpect.debugPlotFPath,params.temporalExpect.debugPlotFname);
    
    if(iOnset == nOnsets)
      axpos = get(plotAxH,'position');
      labelAx = axes('position',[axpos(1) (axpos(2) - .1) axpos(3) .1],'visible','off');
      meanTimingDev = mean(vmTimingDev{iBand});
      text(0.5,0.5,sprintf('mean timing dev: %.2f',meanTimingDev),'verticalalignment','bottom','horizontalalignment','center',...
	   'fontsize',14,'fontweight','bold');
    end
    
    print(plotFPath,'-dpsc','-append');
    close(gcf);
      
  end
    
    
end % for iBand

expectationData = ensemble_init_data_struct;
expectationData.vars{end+1} = 'vmAngles';
expectationData.vars{end+1} = 'vmPeakFreqs';
expectationData.vars{end+1} = 'vmPredictionPerOnset';
expectationData.vars{end+1} = 'vmAreaPerPeak';
expectationData.vars{end+1} = 'vmViolationPerOnset';
expectationData.vars{end+1} = 'vmTimingDev';
expectationData.vars{end+1} = 'vmK';
expectationData.vars{end+1} = 'proportions';
expectationData.vars{end+1} = 'vmDistPerOnset';
expectationData.vars{end+1} = 'vmAngles';
expDataCols = set_var_col_const(expectationData.vars);
expectationData.data{expDataCols.vmAngles} = angleDistVector';
expectationData.data{expDataCols.vmPeakFreqs} = vmPeakFreqs;
expectationData.data{expDataCols.vmPredictionPerOnset} = vmPredictionPerOnset;
expectationData.data{expDataCols.vmViolationPerOnset} = vmViolationPerOnset;
expectationData.data{expDataCols.vmAreaPerPeak} = vmAreaPerPeakList;
expectationData.data{expDataCols.proportions} = vmProportionsPerPeakList;
expectationData.data{expDataCols.vmTimingDev} = vmTimingDev;
expectationData.data{expDataCols.vmDistPerOnset} = vmDistPerPeakPerOnset;
expectationData.data{expDataCols.vmK} = vmK;
expectationData.data{expDataCols.vmAngles} = angleDistVector;
outData = expectationData;

