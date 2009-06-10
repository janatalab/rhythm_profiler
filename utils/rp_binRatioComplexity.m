function outData = rp_binRatioComplexity(inData,params)
%
% looks at the MPP peak ratios that were approximated by
% approx_peak_ratios and returns a ratio of complex bins/simple
% bins


simpleRatios = {'1/8','1/4','1/2','1','2','4','8','16'};


rp = inData;
rp = ensemble_datastruct2tree(rp);


binRatios = rp.peakInfo.approxRatio;
peakHeights = rp.peakInfo.normHeight;

simpleMask = ismember(binRatios,simpleRatios);


simpleEnergy = sum(peakHeights(simpleMask));
complexEnergy = sum(peakHeights(~simpleMask));


ratio = complexEnergy./simpleEnergy;


outData = ratio;
