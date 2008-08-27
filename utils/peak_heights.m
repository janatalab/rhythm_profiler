function peakHeights = peak_heights(varargin)


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
  
  if((rightBorder(iPeak) == peakIdxs(iPeak)) && ~(leftBorder(iPeak) == peakIdxs(iPeak)))
    maxBase = sig(leftBorder(iPeak));
  elseif((leftBorder(iPeak) == peakIdxs(iPeak)) && ~(rightBorder(iPeak) == peakIdxs(iPeak)))
    maxBase = sig(rightBorder(iPeak));
  else
    maxBase = max([sig(leftBorder(iPeak)) sig(rightBorder(iPeak))]);
  end
    
  peakHeights(iPeak,1) = (sig(peakIdxs(iPeak)) - maxBase)./max(sig);
  
end

return
