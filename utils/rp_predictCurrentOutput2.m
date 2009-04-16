function onsetExpectMtx = rp_predictCurrentOutput(varargin)
% removes the effects of current onsets on the resonator Outputs
%
%
% INPUT
%  a rhythm profile structure (ensemble data struct format)
%
% PARAMS
%  params.resonType: 'reson','reson_z', or 'reson_r'
%  params.inputType: '
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 3/17/2009

%ASSUMES WE ARE WORKING WITH IMPULSE INPUTS FOR NOW

for iArg = 1:2:nargin
  switch(varargin{iArg})
   case 'resonBankOut'
    resonBankOut = varargin{iArg+1};
   case 'resonFreqs'
    resonFreqs = varargin{iArg+1};
   case 'Fs'
    Fs = varargin{iArg+1};
   case 'onsetTimesSamps'
    onsetTimesSamps = varargin{iArg+1};
   case 'onsetBorders'
    onsetBorders = varargin{iArg+1};
   case 'BList'
    BList =  varargin{iArg+1};
   case 'AList'
    AList = varargin{iArg+1};
   case 'params'
    params = varargin{iArg+1};
  end
end

nOnsets = length(onsetTimesSamps);
nResons = size(resonBankOut,1);
fid =1;

fprintf(fid,['\nCalculating reson filter predictor, assuming on no' ...
	     ' future input. Onset # ']);
for iOnset = 1:nOnsets
    
  if(mod(iOnset-1,10) == 0)
    fprintf(fid,' %d ',iOnset);
  end

  thisOnsetTimeSamp = onsetTimesSamps(iOnset);
  
  resonBankOutNoOnset = resonBankOut(:,[1:onsetTimesSamps(iOnset)-1]);
  
  if(isempty(resonBankOutNoOnset))
    expectValue = 0;
  else
    
    BAll = [BList{:}];
    AAll = [AList{:}];
    
    b0List = BAll(1:3:end)';
    b1List = BAll(2:3:end)';
    b2List = BAll(3:3:end)';
    
    a0List = AAll(1:3:end)';
    a1List = AAll(2:3:end)';
    a2List = AAll(3:3:end)';
      
    %assuming that current input sample and two samples ago are
    %both zero, since we want a prediction value based on no input.
    x0 = 0;
    x2 = 0;
      
    y1List = resonBankOutNoOnset(:,thisOnsetTimeSamp-1);
    if(thisOnsetTimeSamp <=2)
      y2List = zeros(size(resonBankOutNoOnset,1),1);
    else
      y2List = resonBankOutNoOnset(:,thisOnsetTimeSamp-2);
    end
    
    switch(params.resonType)
     case 'reson_z'
      
      for iReson = 1:nResons
      
	thisResonFreq = resonFreqs(iReson);
	thisResonOutNoOnset = resonBankOutNoOnset(iReson,:);
	
	b0 = b0List(iReson);
	b1 = b1List(iReson);
	b2 = b2List(iReson);
	a0 = a0List(iReson);
	a1 = a1List(iReson);
	a2 = a2List(iReson);
	
	y1 = y1List(iReson);
	y2 = y2List(iReson);
	
	nSamples = round(1./thisResonFreq.* 2 .* Fs);
	expectValue = [];
	
	for iSample = 1:nSamples
	  
	  expectValue(iSample) = (-a1.*y1 -a2.*y2)./a0;
	
	  y2 = y1;
	  y1 = expectValue(iSample);
	
	end
      
	thisResonExpectOut = [thisResonOutNoOnset expectValue];
	
	hilbertThisResonExpectOut = hilbert(thisResonExpectOut);
	normThisResonExpectOut = thisResonExpectOut ./ abs(hilbertThisResonExpectOut);
	
	fpParams.thresh = 0.95;
	peakIdxs = find_peaks(normThisResonExpectOut,fpParams);
	
	peakIdxsToPresent = peakIdxs(peakIdxs <= thisOnsetTimeSamp);
	peakIdxsAfter  = peakIdxs(peakIdxs > thisOnsetTimeSamp);
	
	peakBefore = max(peakIdxsToPresent);
	peakAfter = min(peakIdxsAfter);
	
	currentPhase = (thisOnsetTimeSamp - peakBefore)./(peakAfter - peakBefore).* 2.* pi;
	
	%make angles greater than pi negative angles
	currentPhase(currentPhase>pi) = 2.*pi - currentPhase(currentPhase>pi);
	
	theta = currentPhase;
	R = expectValue(1);
	%onsetExpectMtx(:,iOnset) = hilbertExpectSeries(:,onsetTimesSamps(iOnset));
	if(~isempty(theta))
	  onsetExpectMtx(iReson,iOnset) = R*cos(theta) + R*sin(theta)*i;
	else
	  onsetExpectMtx(iReson,iOnset) = 0;
	end
	
      end %for
      
    end %switch
  end %if isempty(resonBankNoOnset)

end %for iOnset


fprintf(fid,'\n');


