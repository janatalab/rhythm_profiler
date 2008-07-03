function peakMean = peakMeanReson(rp)
%
% finds the peak of the mean reson energy output in an rp struct
%
% 10 July 2007, Stefan Tomic

rpCols = set_var_col_const(rp.vars);

meanEnergy = mean(rp.data{rpCols.resonatorEnergy},2);
resonFreqs = rp.data{rpCols.resonatorFreqs};
peakMean = resonFreqs(find(meanEnergy == max(meanEnergy),1,'first'));

