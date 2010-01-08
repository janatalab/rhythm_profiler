function plot_vmDistibution(inData,params)
  
  
  
%hardcoding some params here for now
params.binSize = 0.01;
params.bandNum = 1;  


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

binSize = params.binSize;
bandNum = params.bandNum;

%The values of distVector should be at the center of the bins
distVector = (0+binSize/2):binSize:(0.5-binSize/2);

axH = params.axHandle;
titleText = params.titleText;
  
bandTimingDev = vmTimingDev{bandNum};  
tdevDist = hist(bandTimingDev,distVector);

meanTD = mean(bandTimingDev);
stdTD = std(bandTimingDev);
bar(axH,distVector,tdevDist);
set(axH,'xlim',[distVector(1) distVector(end)]);
title(titleText,'fontWeight','bold');

xlabel(sprintf('mean : %.2f std: %.2f',meanTD,stdTD));
  



