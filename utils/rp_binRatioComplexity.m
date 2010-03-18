function outData = rp_binRatioComplexity(inData,params)
%
% looks at the MPP peak ratios that were approximated by
% approx_peak_ratios and returns a ratio of complex bins/simple
% bins

fprintf('Calculating MPP peak complex/simple ratio - ');

simpleRatios = {'1/8','1/4','1/2','1','2','4','8','16'};


rp = inData;

%convert rp to regular struct (if not already converted)
if(is_ensemble_datastruct(rp))
  rp = ensemble_datastruct2tree(rp);
end

%use interpolated peak info, if it exists
if( isfield(rp,'interpMPPStruct') && ~isempty(rp.interpMPPStruct))
  fprintf('interpolated peak info exists. Using this data.\n\n');
  peakInfo = rp.interpMPPStruct.peakInfo;
else
  fprintf('interpolated peak info does not exist. Using non-interpolated data.\n\n');
  peakInfo = rp.peakInfo;
end

binRatios = peakInfo.approxRatio;
peakHeights = peakInfo.normHeight;

simpleMask = ismember(binRatios,simpleRatios);


simpleEnergy = sum(peakHeights(simpleMask));
complexEnergy = sum(peakHeights(~simpleMask));


ratio = complexEnergy./simpleEnergy;


outData = ratio;
