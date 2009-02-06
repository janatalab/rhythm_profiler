function outData = plot_mmp_vs_complexity(inData,params)
%
%
%

anSearchCrit.name = 'ipem_proc_series';
anIdx = ensemble_find_analysis_struct(inData,anSearchCrit);
ipemData = inData{anIdx};
ipemDataCols = set_var_col_const(ipemData.vars);
rpList = ipemData.data{ipemDataCols.rp};

anSearchCrit.name = 'complexity_compare';
anIdx = ensemble_find_analysis_struct(inData,anSearchCrit);
complData = inData{anIdx};
complDataCols = set_var_col_const(complData.vars);

anSearchCrit.name = 'parsed_stim_breaks';
anIdx = ensemble_find_analysis_struct(inData,anSearchCrit);
parseInfo = inData{anIdx};
parseInfoCols = set_var_col_const(parseInfo.vars);
offsets = parseInfo.data{parseInfoCols.offset_from_orig};

complexityMeasures = params.complexityMeasures;

for iRP = 1:length(rpList)
  
  rpPath = rpList{iRP};
  [dummy,fstub,ext] = fileparts(rpPath);
  setInfo = regexp(fstub,'set(?<setnum>\d+)_part?(?<partnum>\d+)_.*','names');
  
  rpLoad = load(rpPath);
  thisRP = rpLoad.rp;
  thisRPCols = set_var_col_const(thisRP.vars);
  
  rpParams = thisRP.data{thisRPCols.params};
  hopSize = rpParams.rp.mmpByFrame.hopSize;
  hopFs = 1./hopSize;
  nRPFreqs = length(thisRP.data{thisRPCols.resonatorFreqs});
  
  figure;
    
  params.plot.fig.title = ['Set ' setInfo.setnum ' Part ' setInfo.partnum];
  axHList = plot_rhythmProfile(thisRP,params.plot);
  
  axH = get_axhandle(axHList,'rectPlot_bottom');
  axPos = get(axH,'position');
  
  axes(axH);
  hold on
  
  colorOrder = {'b','r','m'};
  
  for iMeasure = 1:length(complexityMeasures)
    
    if(strcmp(complexityMeasures{iMeasure},'MeanResponse'))
      partnum = str2num(setInfo.partnum);
      setnum = str2num(setInfo.setnum);
      
      if(setnum == 9)
	respData = complData.data{complDataCols.complexityResponses_set9};
      else
	respData = complData.data{complDataCols.complexityResponses_set10};
      end      
      
      respData = mean(respData,1);

      if(isfield(params,'ignoreRespSampRange') && ~isempty(params.ignoreRespSampRange));
	ignoreSamps = [params.ignoreRespSampRange(1):params.ignoreRespSampRange(2)];
	respData(ignoreSamps) = NaN;
      end

      %currently, response Fs = hopFs. This may not be true for
      %future sets.
      respFs = hopFs;
       
      respOffset = offsets((setnum-9)*3 + partnum);
      respOffsetSamps = max(round(respOffset*respFs),1);
      plotXLim = get(axH,'xlim');
      nRespSamps = min(floor(plotXLim(2)*respFs),length(respData));
      useSamps = [respOffsetSamps:respOffsetSamps+nRespSamps-1];
      complexityVector = respData(useSamps);
      timeVector = [1:length(complexityVector)]./respFs;
      
    else
      complexityVector = thisRP.data{thisRPCols.(complexityMeasures{iMeasure})};
      timeVector = [1:length(complexityVector)]./hopFs;
    end
    
   
    %normalize and scale complexityVector to fit in the plot 
    complexityVector = (complexityVector - min(complexityVector))./ ...
			(max(complexityVector) - min(complexityVector));
    complexityVector = complexityVector*(nRPFreqs - 1) + 1;
    
    
    plot(axH,timeVector,complexityVector,'color',colorOrder{mod(iMeasure-1,length(colorOrder))+1});
      
  end
  
  legend(axH,complexityMeasures,'position',[axPos(1)+.04 (axPos(2)+axPos(4)+.03) .2 .03]);
  
  plotFname = ['mmp_vs_complexity_set' setInfo.setnum '_part' ...
	       setInfo.partnum '.ps'];
  print('-dpsc2',fullfile(params.savePath,plotFname));
  close(gcf);
  
end

outData = [];
