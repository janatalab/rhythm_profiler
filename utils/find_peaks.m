function peakIdxs = find_peaks(inSig,params)
% Finds the peak locations in a signal
%
% peakIdxs = find_peaks(inSig,params)
%
% Accepts an input signal and identifies the peak index locations.
% A threshold parameter (param.thresh) should be passed in to
% indicate the threshold under which peaks should be ignored.
% The threshold is useful if working with a signal that is
% noisy. The threshold should be chosen sufficiently above the
% noise floor. The signal may optionally be low pass filtered
% before performing peak detection
%
% INPUTS
%  params.perform: (optional) A cell array of strings of processes to perform. 
%                  Currently, there is only one option, 'lowPass', to
%                  perform a low pass filtering before peak detection.
%  params.thresh:  Value between 0 and 1. Fraction of maximum amplitude to use as a
%                  threshold below which peak detecting will not be performed. This
%                  may be useful if your signal has many small peaks with low amplitudes.
%
%  params.Fs:      Sampling rate of signal. Only needed if
%                  performing low pass filter.
%  params.lpFreq:  Low pass cutoff frequency. Only needed if performing low pass
%                  filter.
%
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author:
% Stefan Tomic 5/07

if(size(inSig,1) > 1 && size(inSig,2) == 1)
  inSig = inSig';
elseif(size(inSig,1) > 1 && size(inSig,2) > 1)
  error('Input signal must be a vector');
end

if(isfield(params,'perform') && ismember('lowPass',params.perform))
  Fs = params.Fs;
  lpFreq = params.lpFreq;
  W = lpFreq/Fs*2;
  [B,A] = butter(12,W,'low');
  inSig = filtfilt(B,A,inSig);
end

%the 0 at the beginning takes care of the diff offset and
%solves for possible peaks at the very beginning of the signal. The
%-1 value at the end takes care of possible peaks at the end of the
%signal.

diffSig = [0 diff(inSig,1) -1];
possiblePeakIdxs = (diffSig(1:end-1) >= 0 & diffSig(2:end) < 0);
threshVal = min(inSig) + (max(inSig) - min(inSig))*params.thresh;
peakIdxs = find((inSig >= threshVal) & possiblePeakIdxs);


return
