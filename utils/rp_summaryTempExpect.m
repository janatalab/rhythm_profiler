function varargout = rp_summaryTempExpect(inData,params)
%
% obtains summary temporal expectation measurements (e.g. mean(mean(timing deviation))
%
% inData is the measurement to be summarized (e.g. coherence, timing deviation)
% as a cell array. Each cell corresponds to the measurements made within a
% band. For example, the coherence inData may look like:
%
%  {[7x1 double]  [9x1 double]  [10x1 double]  [7x1 double]  [6x1 double]}
%
% Four outputs are provided, the mean(mean(measurement)),
% mean(var(measurement)), var(mean(measurement)), and var(var(measurement))
% where the inner mean or var measurement is made within band, and the outer
% mean or var measurement is made across bands.
%
% For single band data, only the mean and var are returned.
%
% Feb. 2010 - Stefan Tomic, First Version 
  
try
  params.throwOutFirstIdx;
catch
  params.throwOutFirstIdx = 0;
end
  
nBands = length(inData);

for iBand = 1:nBands
  
  bandData = inData{iBand};
  
  %throw out first onset
  %this is zero or nan on the timing calcs
  %we should consider whether any data should be recorded
  %for the first onset at all
  if(params.throwOutFirstIdx)
    bandData(1) = [];
  end

  mBandData(iBand) = mean(bandData);
  vBandData(iBand) = std(bandData).^2;
  
end

varargout{1} = mean(mBandData);
varargout{2} = mean(vBandData); 

if(nBands > 1)
  varargout{3} = std(mBandData).^2;
  varargout{4} = std(vBandData).^2;
end