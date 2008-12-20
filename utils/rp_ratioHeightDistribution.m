function outData = rp_ratioHeightDistribution(inData,params)
%
% testing function for analyzing ratios of peak heights

plotPath = params.plotPath;

nData = length(inData);

for iData = 1:nData

  rpLoad = load(inData{iData});
  thisRP = rpLoad.rp;
  thisRPCols = set_var_col_const(thisRP.vars);
  
  ratioTally = thisRP.data{thisRPCols.ratioTally};
  rtCols.normPeakFreq = 1;
  rtCols.heights = 2;
  rtCols.ratioBinIdx = 3;
  rtCols.errorVec = 4;
  
  nanMask = isnan(ratioTally(:,rtCols.ratioBinIdx));
  
  nanHeights = ratioTally(nanMask,rtCols.heights);
  notNanHeights = ratioTally(~nanMask,rtCols.heights);
  

  nanErrorVec = ratioTally(nanMask,rtCols.errorVec); 

  h_bins = [.05:.05:1];
  
  h_count(:,1) = hist(nanHeights,h_bins)';
  h_count(:,2) = hist(notNanHeights,h_bins)';
  
  figure;
  [dummy1,fstub,dummy2] = fileparts(inData{iData});
  figTitle = strrep(fstub,'_','\_');
  axes('position',[.35 .95 .3 .04],'visible','off');
  text(.5,.5,figTitle,'horizontalalignment','center','fontsize',14,'fontweight','bold');
  title(fstub);
  set(gcf,'position',[100 100 800 1000],'paperposition',[.25 .25 8 10]); 
  
  subplot(4,1,1);
  
  bar(h_bins,h_count);
  set(gca,'xlim',[0 1.1]);
  title('Peak Height Ratio to Heighest Peak in Frame');
  legend('nan','not nan','location','north'); 
  
  
  nanNormPeakFreqs = ratioTally(nanMask,rtCols.normPeakFreq);
  notNanNormPeakFreqs = ratioTally(~nanMask,rtCols.normPeakFreq);
  
  f_bins = [0:.125:16];
  f_count(:,1) = hist(nanNormPeakFreqs,f_bins)';
  % f_count(:,2) = hist(notNanNormPeakFreqs,f_bins)';
  
  subplot(4,1,2);
  bar(f_bins,f_count);
  title('Peak Freq Ratio to Highest Peak in Frame (bin failures only)');
  set(gca,'xlim',[0 16]);
  set(gca,'xtick',[0:.5:16]);
  rotateticklabel(gca,90);
  
  subplot(4,1,3);
  
  hist(nanErrorVec,30);
  title('Error ratios to closest bin (bin failures only)');
  set(gca,'xtick',[0:.05:1])

  
  subplot(4,1,4);
  largeErrorIdx = find(nanErrorVec > .15);
  hist(nanNormPeakFreqs(largeErrorIdx),30);
  title(['Frequency ratios of peaks that failed to bin with greater' ...
	 ' than .15 error']);
  set(gca,'xtick',[0:.5:16]);
  rotateticklabel(gca,90);
  
  
 
  plotFPath = fullfile(plotPath,[fstub '_binerrors.ps']);
  
  print('-dpsc2',plotFPath);
  
  
  close(gcf);
  
end
