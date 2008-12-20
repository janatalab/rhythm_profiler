function outData = rp_ratioEntropyAnalysis(inData,params)

% Processes an rp struct through a trained meter classifier neural network
%
% outData = rp_ratioEntropyAnalysis(inData,params)
%
%
% 
% INPUT
%  inData: 
% 
% Copyright (c) 2008 The Regents of the University of California
% All Rights Reserved
%
% Author:
% 12/17/08 First Version, Stefan Tomic

rpList = inData;

nRP = length(rpList);

for iRP = 1:nRP
  
  fprintf('\n\nLoading rp struct from  %s...\n',rpList{iRP});
  rpLoad = load(rpList{iRP});
  thisRP = rpLoad.rp;
  thisRPCols = set_var_col_const(thisRP.vars);
  
  rpParams = thisRP.data{thisRPCols.params};
  ratioLabels =  rpParams.rp.resonatorBank.peakFinder.ratioLabels;
  nRatios = length(ratioLabels);
  
  ratioBinsByFrame = thisRP.data{thisRPCols.ratioBinsByFrame};
  
  %%% complex ratio energy over all bin energy analysis %%%
  
  if(ismember('binEnergyRatioByFrame',params.perform))
    
    fprintf('process ''binEnergyRatioByFrame'' was specified.\n');
    fprintf(['Calculating relative energy in complex ratio bins to' ...
	     ' all bins\n']);
    
    newCols = {'binEnergyRatioByFrame'};
    allCols = union(thisRP.vars, newCols)
    if(~isempty(setxor(thisRP.vars,allCols)))
      thisRP.vars = {thisRP.vars{:} newCols{:}};
    end
    
    simpleRatios = {'1/8','1/4','1/2','1','2','4','8','16'};
    [dummy,simpleRatioBinIdxs] = ismember(simpleRatios,ratioLabels);
    
 
    simpleRatioBinMask = zeros(nRatios,1);
    simpleRatioBinMask(simpleRatioBinIdxs) = 1;
    

    
    complexRatioBinsByFrame = ratioBinsByFrame(~simpleRatioBinMask,:);
    
    complexBinEnergyByFrame = sum(complexRatioBinsByFrame,1);
    allEnergyByFrame = sum(ratioBinsByFrame,1);
  
    energyRatioByFrame = complexBinEnergyByFrame ./ allEnergyByFrame;
    
    thisRPCols = set_var_col_const(thisRP.vars);
    thisRP.data{thisRPCols.binEnergyRatioByFrame} = energyRatioByFrame';

    
  end
  
  if(ismember('signedKLDivByFrame',params.perform))
    %%% kl divergence analysis %%%
  cra
    fprintf('process ''signedKLDivByFrame'' was specified.\n');
    fprintf(['Calculating KL Divergence by frame and signing results by' ...
	     ' relative entropy to the mean entropy']);
    
    newCols = {'signedKLDivByFrame'};
    allCols = union(thisRP.vars, newCols);
    if(~isempty(setxor(thisRP.vars,allCols)))
      thisRP.vars = {thisRP.vars{:} newCols{:}};
    end
    
    peakInfo = thisRP.data{thisRPCols.peakInfo};
    peakInfoCols = set_var_col_const(peakInfo.vars);
    meanRatioBins = peakInfo.data{peakInfoCols.approxRatio};
    meanRatioIdxs = peakInfo.data{peakInfoCols.ratioBinIdx};
   
    %sanity check to make sure that the ratios specified in peakInfo
    %are included in the complete ratio list from rp params
    [dummy,checkIdx] = ismember(meanRatioBins,ratioLabels);
    if(~all(meanRatioIdxs == checkIdx))
      warning(['ratioBinIdx column doesn''t match corresponding index' ...
	       ' in ratioLabels in the params for this RP struct.' ...
	       ' This should be reviewed.']);
    end
  
    meanRatioHeights = peakInfo.data{peakInfoCols.normHeight};
    meanRatioVec = zeros(nRatios,1);
    meanRatioVec(meanRatioIdxs) = meanRatioHeights;
    
    %normalize the vector of mean ratios
    normMeanRatioVec = meanRatioVec./sum(meanRatioVec)+eps;
    meanEntropy = sigEntropy(normMeanRatioVec);
    
    nFrames = size(ratioBinsByFrame,2);
    %normalize the frame by frame ratios and calculate kl divergence
    for iFrame = 1:nFrames
      
      frameRatioVec = ratioBinsByFrame(:,iFrame);
      normFrameRatioVec = frameRatioVec./sum(frameRatioVec)+eps;
      
      kld(iFrame,1) = sum(normMeanRatioVec.*log2(normMeanRatioVec./normFrameRatioVec));
      
      frameEntropy = sigEntropy(normFrameRatioVec);
      
      %if instant entropy is less than mean entropy,then we'll make
      %kld negative
      if(frameEntropy < meanEntropy)
	kld(iFrame) = -kld(iFrame);
      end
    
    end
    
    thisRPCols = set_var_col_const(thisRP.vars);
    thisRP.data{thisRPCols.signedKLDivByFrame} = kld;
    
  end
  
  
  rp = thisRP;
  clear thisRP;
  
  fprintf('\nSaving new data to rp struct in %s...\n',rpList{iRP});
  save(rpList{iRP},'rp');
  
 
  
end

outData = ensemble_init_data_struct;
outData.vars = {'filename'};
outData.data = rpList;


return
