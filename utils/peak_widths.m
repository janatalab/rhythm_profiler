function [outData] = peak_widths(varargin)
% Calculates the widths of peaks in a signal
%
% returns the nearest indices to the peaks of a signal where the 
% slope changes sign. Two indices are returned for each peak,
% marking the left and right borders. 
%
% This function is called by parameter,value pairs: signal and peakIdxs
%
% outData = peak_widths('signal',sig,'peakIdxs',peaks,'params',params)
%
% where 'signal' corresponds to the signal to scan and 'peakIdxs'
% corresponds to the peak indices in the signal
%
% params.runMode:  'border_indices' will make the function
%                  return the actual indices where the derivative changes sign
%                  'width_half_height' will return the indices
%                  nearest to the base of the peak that cross the half max threshold.
%                  default is 'border_indices'
% params.interpolate: 0 or 1, whether or not to perform linear
%                     interpolation to determine the width
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author:
% July 19, 2007 - Stefan Tomic


for iarg = 1:2:nargin

  switch varargin{iarg}
   case 'signal'
    sig = varargin{iarg+1};
   case 'peakIdxs'
    peakIdxs = varargin{iarg+1};
   case 'params'
    params = varargin{iarg+1};
   case 'xVals'
    xVals = varargin{iarg+1};
  end

end

try
  xVals;
catch
  xVals = 1:length(sig);
end

if(~exist('params','var') || ~isfield(params,'runMode'))
  params.runMode = 'border_indices';
end

if(~isfield(params,'interpolate'))
  params.interpolate = 0;
end

%if this is a row vector, make it a column vector
if(size(sig,2) > size(sig,1))
  sig = sig';
end

diffSig = [0 ; diff(sig)];

nPeaks = length(peakIdxs);

leftBorder = 1;
for iPeak = 1:nPeaks

  if(iPeak == 1)
    leftBorder(iPeak) = 1;
  else
    leftBorder(iPeak) = rightBorder(iPeak-1);
  end
  
  if(iPeak ~= nPeaks)
    rightBorder(iPeak) = peakIdxs(iPeak+1);
  else
    rightBorder(iPeak) = length(sig);
  end
  
  idxsLeft  = [leftBorder(iPeak):peakIdxs(iPeak)];
  idxsRight = [peakIdxs(iPeak)+1:rightBorder(iPeak)];
  lChangeSign = find(diffSig(idxsLeft) < 0,1,'last');
  rChangeSign = find(diffSig(idxsRight) > 0,1,'first');

  if(isempty(lChangeSign))
    lChangeSign = 1;
  end
  
  if(isempty(rChangeSign))
    rChangeSign = length(idxsRight) + 1;
  end
  
  leftBorder(iPeak) = leftBorder(iPeak) + lChangeSign - 1;
  rightBorder(iPeak) = peakIdxs(iPeak) + rChangeSign - 1;
  
  if(strcmp(params.runMode,'width_half_height'))
    if((rightBorder(iPeak) == peakIdxs(iPeak)) && ~(leftBorder(iPeak) == peakIdxs(iPeak)))
      maxBase = sig(leftBorder(iPeak));
    elseif((leftBorder(iPeak) == peakIdxs(iPeak)) && ~(rightBorder(iPeak) == peakIdxs(iPeak)))
      maxBase = sig(rightBorder(iPeak));
    else
      maxBase = max([sig(leftBorder(iPeak)) sig(rightBorder(iPeak))]);
    end
    
    %halfHeight(iPeak) = sig(peakIdxs(iPeak)) - (sig(peakIdxs(iPeak)) - maxBase)./2;
    
    thisPeak = sig(peakIdxs(iPeak));
    halfPower(iPeak) = maxBase + (thisPeak - maxBase)*(1/sqrt(2));
    
    leftBorderToPeak = leftBorder(iPeak):peakIdxs(iPeak);
    peakToRightBorder = peakIdxs(iPeak):rightBorder(iPeak);
    
    lRelIdx = find(sig(leftBorderToPeak) >= halfPower(iPeak),1,'first');
    rRelIdx = find(sig(peakToRightBorder) >= halfPower(iPeak),1,'last');
       
    lGTIdx = leftBorder(iPeak) + lRelIdx - 1;
    rGTIdx = peakIdxs(iPeak) + rRelIdx - 1;
    
    if(params.interpolate)
      
      if(lGTIdx == 1)
	leftInterpVal = xVals(lGTIdx);
      else
	leftRatio = (sig(lGTIdx) - halfPower(iPeak))./(sig(lGTIdx)-sig(lGTIdx-1));
	leftInterpVal = xVals(lGTIdx) - leftRatio*(xVals(lGTIdx)-xVals(lGTIdx-1));
      end
	
      if(rGTIdx==length(xVals))
	rightInterpVal = xVals(rGTIdx);
      else
	rightRatio =(sig(rGTIdx) - halfPower(iPeak))./(sig(rGTIdx)-sig(rGTIdx+1));
	rightInterpVal = xVals(rGTIdx) + rightRatio*(xVals(rGTIdx+1)-xVals(rGTIdx));  
      end     

      leftHalfHeight(iPeak) = leftInterpVal;
      rightHalfHeight(iPeak) = rightInterpVal;
    else
      leftHalfHeight(iPeak) = xVals(lGTIdx);
      rightHalfHeight(iPeak) = xVals(rGTIdx);
    end
  end
    
  
end


outData = repmat(NaN,2*length(peakIdxs),1);

switch(params.runMode)

 case 'border_indices'
  outData(1:2:end-1) = leftBorder;
  outData(2:2:end) = rightBorder;
 case 'width_half_height'
  outData(1:2:end-1) = leftHalfHeight;
  outData(2:2:end) = rightHalfHeight;
  
  
end 
   
return


