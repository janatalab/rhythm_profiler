function plot_vmDistibution(inData,params)
  
  
  
%hardcoding some params here for now
params.binSize = 0.01;
params.bandNum = 1;  
params.plot_calc = 'fulfill';

searchParams.type = 'rhythm_profile';
anIdx = ensemble_find_analysis_struct(inData,searchParams);
rp = inData{anIdx};

searchParams.type = 'aud';
anIdx = ensemble_find_analysis_struct(inData,searchParams);
inputSig = inData{anIdx};
  

rpCols = set_var_col_const(rp.vars);
vmExpect = rp.data{rpCols.vmExpect};
vmExpectCols = set_var_col_const(vmExpect.vars);
vmTimingDev = vmExpect.data{vmExpectCols.vmTimingDev};
vmFulfill = vmExpect.data{vmExpectCols.vmLogFulfillPerOnset};

cohStruct = rp.data{rpCols.coherence};
cohCols = set_var_col_const(cohStruct.vars);
coh = cohStruct.data{cohCols.cohPerPeakPerBand};

binSize = params.binSize;
bandNum = params.bandNum;

%The values of distVector should be at the center of the bins


axH = params.axHandle;
titleText = params.titleText;
  
bandTimingDev = vmTimingDev{bandNum};  
bandFulfill = vmFulfill{bandNum};
bandCoh = coh{bandNum};

switch(params.plot_calc)
  
 case 'timing_dev'
  distVector = (0+binSize/2):binSize:(0.5-binSize/2);
  tdevDist = hist(bandTimingDev,distVector);
  meanTD = nanmean(bandTimingDev);
  stdTD = nanstd(bandTimingDev);
 
 case 'fulfill'
  distVector = (-1+binSize/2):binSize:(1-binSize/2);
  tdevDist = hist(bandTimingDev,distVector);
  meanTD = nanmean(bandTimingDev);
  stdTD = nanstd(bandTimingDev);
  
 case 'coh'
  distVector = [(0+binSize/2):binSize:(1-binSize/2)];
  tdevDist = hist(bandCoh,distVector);
  meanTD = nanmean(bandCoh);
  stdTD = nanstd(bandCoh);
  
  
  
  
end  
  
bar(axH,distVector,tdevDist);
set(axH,'xlim',[distVector(1) distVector(end)]);
title(titleText,'fontWeight','bold');

xlabel(sprintf('mean : %.2f std: %.2f',meanTD,stdTD));
  



