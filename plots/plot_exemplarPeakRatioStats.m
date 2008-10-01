function outData = train_meterEstimator(inData,params)
%
%
%
%

searchCrit.name = 'exemplars';
searchIdx = ensemble_find_analysis_struct(inData,searchCrit);
exemplars = inData{searchIdx};
exemplarsCols = set_var_col_const(exemplars.vars);

searchCrit.name = 'ipem_proc_series';
searchIdx = ensemble_find_analysis_struct(inData,searchCrit);
ipemProc = inData{searchIdx};
ipemProcCols = set_var_col_const(ipemProc.vars);

matFileList = ipemProc.data{ipemProcCols.rp};
classes = exemplars.data{exemplarsCols.class};
inputFileList = exemplars.data{exemplarsCols.audFileList};
[classList,dummy,allClassTargets] = unique(classes);
nClasses = length(classList);
nFiles = length(matFileList);

ratioLabels = params.ratioLabels;

idxs_used = [];
nnet_inputs = zeros(length(params.ratioLabels),0);
for iFile = 1:nFiles
  
  fPath = matFileList{iFile};
  loadRP = load(fPath);
  thisRP = loadRP.rp;
  thisRPCols = set_var_col_const(thisRP.vars);
  peakInfo = thisRP.data{thisRPCols.peakInfo};
  peakInfoCols = set_var_col_const(peakInfo.vars);
  ratios = peakInfo.data{peakInfoCols.approxRatios};
  heights = peakInfo.data{peakInfoCols.normHeight};
  
  if(~isempty(ratios))
    idxs_used(end+1) = iFile;
    [dummy,idxs1,idxs2] = intersect(ratioLabels,ratios);
    nnet_inputs(idxs1,end+1) = heights(idxs2);
  end
    
end

%remove the ratio=1 peak and ratios that have no values
ratio1idx = find(strcmp('1',params.ratioLabels));
removeIdxs = find(~any(nnet_inputs,2));
removeIdxs = [ratio1idx ; removeIdxs];
nnet_inputs(removeIdxs,:) = [];
ratioLabels(removeIdxs) = [];

for iClass = 1:length(classList)
  exemplarsThisClass = find(allClassTargets == iClass);
  meanRatioPerCategory(iClass,:) = mean(nnet_inputs(:,exemplarsThisClass),2);
  stdErrorPerCategory(iClass,:) = std(nnet_inputs(:,exemplarsThisClass),[],2)./sqrt(length(exemplarsThisClass));;
end

fig_h = figure;ax_h = axes;
set(gcf,'position',[10 10 2000 600]);
set(gcf,'paperposition',[0.25 2.5 20 6]);
bar_h = bar(ax_h,meanRatioPerCategory');
add_errorbars(bar_h,stdErrorPerCategory','k');
set(ax_h,'xlim',[0 length(ratioLabels)+1]);
set(ax_h,'ylim',[0 max(meanRatioPerCategory(:))+ max(stdErrorPerCategory(:))+0.02]);
set(ax_h,'xtick',[1:length(ratioLabels)]);
set(ax_h,'xticklabel',ratioLabels);
set(ax_h,'ytick',[0.1:0.1:0.5]);
colormap(gray);
legend(classList);

print(fig_h,'-deps',fullfile(params.plotPath,params.plotFname));
%close(fig_h);


outData = [];

return

