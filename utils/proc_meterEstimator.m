function outData = proc_meterEstimator(inData,params)
% Processes an rp struct through a trained meter classifier neural network
%
% outData = proc_meterEstimator(inData,params)
%
%
% 
% INPUT
%  inData: two cells. One cell should be the output from
%  ipem_proc_series that specifies paths and filenames to rp
%  structs. The other cell should contain the neural net.
% 
% Copyright (c) 2008 The Regents of the University of California
% All Rights Reserved
%
% Author:
% 12/16/08 First Version, Stefan Tomic

rpList = inData{1};
net = inData{2};

weightMatrix = net.IW{1};
bias = net.b{1};

nRP = length(rpList);

netBins = params.net.ratioLabels;

for iRP = 1:nRP
  
  rpLoad = load(rpList{iRP});
  thisRP = rpLoad.rp;
  thisRPCols = set_var_col_const(thisRP.vars);
  
  ratioBinsByFrame = thisRP.data{thisRPCols.ratioBinsByFrame};
  binsThisRP = thisRP.data{thisRPCols.params}.rp.resonatorBank.peakFinder.ratioLabels;

  [includeBinMask,binIdx] = ismember(binsThisRP,netBins);
  
  ratioBinsByFrame = ratioBinsByFrame(includeBinMask,:);
  binIdx = binIdx(binIdx ~=0);
  ratioBinsByFrame = ratioBinsByFrame(binIdx,:);
  
  %eliminate ratio = 1;
  ratio1idx = strmatch('1',netBins,'exact');
  ratioBinsByFrame(ratio1idx,:) = [];
  
  nFrames = size(ratioBinsByFrame,2);
  biasMtx = repmat(bias,1,nFrames);
  
  biasedWeightedFrames = weightMatrix * ratioBinsByFrame + biasMtx;
  
  %apply logsig function
  logSigFrames = 1 ./ (1 + exp(-biasedWeightedFrames));
  
  %calculate entropy value for each frame
  for iFrame = 1:nFrames
    fEntropy(iFrame) = sig_entropy(:,iFrame);
  end
  
  
  
end




return
