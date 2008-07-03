%function outData = temporalExpectationError(inData,params)
%
%
%
%

%rp = inData;

onsetThreshold = 0.1;

rpCols = set_var_col_const(rp.vars);

onsetPattern = rp.data{rpCols.sumDenv};
filterPattern = squeeze(sum(rp.data{rpCols.resonatorOut},2));

%shift filters back by two samples to account for phase shift
onsetPattern = onsetPattern(:,1:end-2);
filterPattern = filterPattern(:,3:end);

normOnsetPattern = onsetPattern./max(abs(onsetPattern(:)));
normFilterPattern = filterPattern./max(abs(filterPattern(:)));

onsetPatternMask = (normOnsetPattern  > onsetThreshold);
filterPatternMask = (abs(normFilterPattern) > onsetThreshold);
expectationMask = onsetPatternMask & filterPatternMask;
%expectationMask = filterPatternMask;


expectationMatrix = zeros(size(normFilterPattern));
expectationMatrix(expectationMask) = (normOnsetPattern(expectationMask)-normFilterPattern(expectationMask)) ./ normFilterPattern(expectationMask);

figure;

for iband = 1:5

  subplot(5,1,iband);
  plot(normOnsetPattern(iband,:),'r--');
  hold on  
  plot(normFilterPattern(iband,:),'b--');
  expectationMatrixBand = expectationMatrix(iband,:) ./ max(abs(expectationMatrix(iband,:)));

  plot(expectationMatrixBand,'g');

end

%return

