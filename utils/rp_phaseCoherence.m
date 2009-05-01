function outData = rp_phaseCoherence(inData,params)
% Calculates coherence among vectors close to important angles (0,pi,pi/2,pi/3,pi,4) etc.
% 
% outData = rp_phaseCoherence(inData,params)
% 
% INPUTS:
% inData: a rhythm profile struct
%            
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 04/30/2009

%hard coding params here. If this becomes a useful function, params
%can be abstracted out

%ONLY WORKS ON SINGLE BANK RIGHT NOW

TEST_ANGLES = 0;

params.metricLevelToleranceMs = 100;

anglesQuad1 = pi./[6 4 3 2];
inspectAngles = [];
for iInspect = 1:4
  inspectAngles = [inspectAngles anglesQuad1+(pi/2).*(iInspect-1)];
end

inspectAngles(inspectAngles > pi) = -2.*pi +inspectAngles(inspectAngles > pi);
inspectAngles = sort(inspectAngles);

mlToleranceSec = params.metricLevelToleranceMs./1000;

rp = inData;
if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

expectErrorStruct = rp.expectationError;
onsetExpectMtx = expectErrorStruct.onsetExpectMtx;
inputHeightList = expectErrorStruct.onsetHeightByBank{1};
resonFreqs = rp.resonatorFreqs;

nOnsets = size(onsetExpectMtx,2);

hsvSel = hsv(8);
for iOnset = 1:nOnsets
  
  peakFreqsNow = expectErrorStruct.vmPeakFreqs{iOnset};
  if(~isempty(peakFreqsNow))
    
    inputHeight = inputHeightList(iOnset);
    
    [dummy,peakIdxs] = ismember(peakFreqsNow,resonFreqs);
    vectorsNow = onsetExpectMtx(peakIdxs,iOnset);
    phasesNow = angle(vectorsNow);
    periodsNow = 1./peakFreqsNow;
    tolerancePerPhase = mlToleranceSec ./ periodsNow .* (2.*pi);
    
    vecs =  cos(phasesNow) + i*sin(phasesNow);
    coh1 = [];
    coh2 = [];
    for iInsAngle = 1:length(inspectAngles)
      insAngle = inspectAngles(iInsAngle);
      insVector1 = cos(insAngle) +i*sin(insAngle);
      insVector2 = inputHeight*cos(insAngle) + inputHeight*i*sin(insAngle);
      diffAngles = abs(phasesNow - insAngle);
      diffAngles(diffAngles > pi) = 2*pi - diffAngles(diffAngles > pi);
      vectorsInRange = find(diffAngles <= tolerancePerPhase');
      
      if(TEST_ANGLES)
	figure(1);
	hold off;
	compV = cos(insAngle) + i*sin(insAngle);
	compass(compV,'k');
	hold on
	for idiff = 1:length(diffAngles)
	  
	  colorspec = hsvSel(idiff,:);
	  extentV1 = cos(insAngle+tolerancePerPhase(idiff)) + i*sin(insAngle+tolerancePerPhase(idiff));
	  extentV2 = cos(insAngle-tolerancePerPhase(idiff)) + i*sin(insAngle-tolerancePerPhase(idiff));
	  v1H = compass(extentV1,':');
	  v2H = compass(extentV2,':');
	  
	  if(ismember(idiff,vectorsInRange))
	    v3H = compass(vecs(idiff),'-');
	    set(v3H,'linewidth',2);
	  else
	    v3H = compass(vecs(idiff),'--');
	  end
	
	  set(v1H,'color',colorspec);
	  set(v2H,'color',colorspec);
	  set(v3H,'color',colorspec);
	  
	end
	
	pause(1.5);
	
      end %if(TEST_ANGLES)
      
      useVecs = vectorsNow(vectorsInRange);
      numerator1 = sum(useVecs.*conj(insVector1)).*conj(sum(useVecs.*conj(insVector1)));
      coh1(iInsAngle) = numerator1/(sum(useVecs.*conj(useVecs))*sum(insVector1.*conj(insVector1)));
      numerator2 = sum(useVecs.*conj(insVector2)).*conj(sum(useVecs.*conj(insVector2)));
      coh2(iInsAngle) = numerator2/(sum(useVecs.*conj(useVecs))*sum(insVector2.*conj(insVector2)));
    
    end %for iInsAngle
    
    meanCohPerOnset1(iOnset) = nanmean(coh1);
    cohZeroPerOnset1(iOnset) = coh1(inspectAngles == 0);
    meanCohPerOnset2(iOnset) = nanmean(coh2);
    cohZeroPerOnset2(iOnset) = coh2(inspectAngles == 0);
    
  end %if(~isempty(peakFreqsNow))
  
end %for iOnset

coherence = ensemble_init_data_struct;
coherence.vars = {'meanCohPerOnset1','meanCohPerOnset2','cohZeroPerOnset1','cohZeroPerOnset2'};
cohCols = set_var_col_const(coherence.vars);

coherence.data{cohCols.meanCohPerOnset1} = meanCohPerOnset1;
coherence.data{cohCols.meanCohPerOnset2} = meanCohPerOnset2;
coherence.data{cohCols.cohZeroPerOnset1} = cohZeroPerOnset1;
coherence.data{cohCols.cohZeroPerOnset2} = cohZeroPerOnset2;

inData.vars = {inData.vars{:} 'coherence'};
inDataCols = set_var_col_const(inData.vars);
inData.data{inDataCols.coherence} = coherence;
outData = inData;

