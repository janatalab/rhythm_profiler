function approxRatios = approx_peak_ratios(varargin)


for iarg = 1:2:nargin

  switch varargin{iarg}
   case 'peakFreqs'
    peakFreqs = varargin{iarg+1};
   case 'params'
    params = varargin{iarg+1};
  end

end

try
  maxMult = params.maxMult;
catch
  maxMult = 16;
end

try
  errorTolerance = params.errorTolerance;
catch
  errorTolerance = .04;
end

%express peakFreqs in relation to min peakFreq
peakFreqs = peakFreqs./min(peakFreqs);


%we're going to try and find the
%least multiplier that will nicely
%characterize all the peak frequencies as ratios
for iMult = 1:maxMult
  
  checkRatios = peakFreqs.*iMult;
  roundCheckRatios = round(checkRatios);
  
  %if any rounded ratios are 0, we know this can't be right, so go
  %to the next loop iteration
  if(any(roundCheckRatios == 0))
    continue;
  else
    errorPct = abs(roundCheckRatios - checkRatios)./roundCheckRatios;
  end
  
  if(all(errorPct < repmat(errorTolerance,size(checkRatios))))
    approxRatios = roundCheckRatios;
    return
  end

end

  

%if we didn't find good ratios in the loop, just return a vector of
%NaNs for now. Eventually, we may want to isolate those peaks that
%can't be expressed as simple ratios and still return those that we can
approxRatios = repmat(NaN,size(peakFreqs));
