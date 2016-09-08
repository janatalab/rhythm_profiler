function outData = rp_binRatioComplexity(inData,params)
%
% looks at the MPP peak ratios that were approximated by
% approx_peak_ratios and returns a ratio of complex bins/simple
% bins

% 07Sep2016 Petr Janata - added ability to submit different set of simple
%                         ratios, and also to pass in just the peakInfo
%                         structure rather than the entire rp structure

fprintf('Calculating MPP peak complex/simple ratio - ');

if ~exist('params','var')
  params = struct;
end

if isfield(params,'simpleRatios')
  simpleRatios = params.simpleRatios;
else
  simpleRatios = {'1/8','1/4','1/2','1','2','4','8','16'};
end

if isfield(params,'inputStructType')
  inputType = params.inputStructType;
else
  inputType = 'rp';
end

% If the input structure is a rhythm profiler structure, extract the peak
% info structure. Otherwise assume it is a peakinfo structure
if strcmp(inputType, 'rp')
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
else
  peakInfo = ensemble_datastruct2tree(inData);
end

binRatios = peakInfo.approxRatio;
peakHeights = peakInfo.normHeight;

simpleMask = ismember(binRatios,simpleRatios);


simpleEnergy = sum(peakHeights(simpleMask));
complexEnergy = sum(peakHeights(~simpleMask));


ratio = complexEnergy./simpleEnergy;


outData = ratio;
