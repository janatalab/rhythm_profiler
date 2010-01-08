function outData = get_ppResonPeakInfo(pp,params);
%
% obtains reson peak info from the pp (spline interpolated) structure
% see get_resonPeakInfo for the version that operates directly on the signal
  
  
pfp_params.perform.peakHeights = 1;
pfp_params.peakHeights.transformation = 'none';
pfp_params.peakHeights.minPeakHeight = params.minPeakHeight;
pfp_params.peakHeights.calcFrom = 'higher';

%obtain the peaks
[peaks,troughs,peakMags,troughMags,peakHeights,normPeakHeights,baseList,baseMags] = pp_find_peaks('pp',pp,'params',pfp_params);


maxPeak = find(peakMags == max(peakMags),1,'first');
baseWidths = baseList(2:2:end) - baseList(1:2:end-1);

outData.baseWidths = baseWidths;
outData.peakFreq = peaks';
outData.normPeakFeq = peaks' ./ peaks(maxPeak);
outData.peakHeight = peakHeights';
outData.normHeight = normPeakHeights';

