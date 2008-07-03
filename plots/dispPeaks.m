function outData = dispPeaks(inData,params)

rp = inData;
rpCols = set_var_col_const(rp.vars);

ax = params.ax;
set(ax,'visible','off');


nSets = length(rp.data{rpCols.peakResonFreqs});

for idx = 1:nSets
  peakFreqs = rp.data{rpCols.peakResonFreqs}{idx};
  meanEnergy = rp.data{rpCols.meanResonEnergy}{idx};
  resonFreqs = rp.data{rpCols.resonatorFreqs}{idx};
  maxPeakEnergyFreq = resonFreqs(find(meanEnergy == max(meanEnergy)));
  normPeakFreqs = peakFreqs ./ maxPeakEnergyFreq;
  nPeaks = length(peakFreqs);
  
  if(isfield(params,'header'))
    peakFindHeader = sprintf('%s\n\n',strrep(params.header{idx},'_','\_'));
  else
    peakFindHeader = '';
  end
  
  if(params.dispWidths)
    peakFindHeader = [peakFindHeader sprintf('Peak   Norm   Q Factor\n')];
  else
    peakFindHeader = [peakFindHeader sprintf('Peak   Norm\n')];
  end
  if(size(peakFreqs,2) > size(peakFreqs,1))
    peakFreqs = peakFreqs';
  end
  
  if(size(normPeakFreqs,2) > size(normPeakFreqs,1))
    normPeakFreqs = normPeakFreqs';
  end
   
  if(params.dispWidths)
    peakWidths = rp.data{rpCols.peakWidths}{idx};
    QFactor = rp.data{rpCols.QFactor}{idx};
    if(size(QFactor,2) > size(QFactor,1))
      QFactor = QFactor';
    end
    peakFindText = [peakFindHeader sprintf('%0.2f%8.2f%9.2f\n',[peakFreqs ...
		    normPeakFreqs QFactor]')];
  else
    peakFindText = [peakFindHeader sprintf('%0.2f%8.2f\n',[peakFreqs normPeakFreqs]')];
  end
  axes(ax);
  t = text((idx-1)./nSets,0.8,peakFindText,'VerticalAlignment','top');
    
end

return
