function outData = rp_complexResonOut(rp,params)
% removes the effects of current onsets on the resonator Outputs
% ATTEMPT AT SPLINE INTERPOLATING COMPLEX SIGNAL
%
% INPUT
%  a rhythm profile structure (ensemble data struct format)
%
% PARAMS
%  params.resonType: 'reson','reson_z', or 'reson_r'
%  params.inputType: '
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 12/7/09

% we shouldn't have to check time lims here anymore
% since the rhythm profile should have used the time lim
% at the first stage of processing
%timeLimSecs = params.timeLimSecs;
%timeLimSamps = round(timeLimSecs*Fs);

fid =1;
Fs = params.Fs;

rpCols = set_var_col_const(rp.vars);

resonOut = rp.data{rpCols.resonatorOut};

onsetInfo = rp.data{rpCols.onsetInfo};
onsetInfoCols = set_var_col_const(onsetInfo.vars);
onsetBordersByBand = onsetInfo.data{onsetInfoCols.onsetBordersByBand};

nBands = size(resonOut,1);
for iBand = 1:nBands
  
  %although hilbert function reports that it operates along columns
  %this seems not to be the case
  complexResonBandOut = hilbert(squeeze(resonOut(iBand,:,:))')';

  %performing complex conjugate of the hilbert transform
  %for some reason, the hilbert transform outputs the complex
  %conjugate when operating on a matrix rather than on a vector
  complexResonBandOut = conj(complexResonBandOut);
  complexResonOut(iBand,:,:) = complexResonBandOut;
end

%SHOULD I ADD A PARAMS HERE TO CHECK WHETHER TO REMOVE ONSETS?
onsetBorders = onsetBordersByBand{iBand};
nOnsets = length(onsetBorders)./2;
  
%find sample indices that correspond to onset times. These will be removed.

complexResonOutPatched = complexResonOut;
allSamps = 1:size(resonOut,3);

%for testing
peakInfo = rp.data{rpCols.peakInfo};
piCols = set_var_col_const(peakInfo.vars);
peakIdxs = peakInfo.data{piCols.peakIdxs};
onsetTimes = rp.data{rpCols.onsetInfo}.data{1}{1};

for iOnset = 1:nOnsets
  %removeSamps = [removeSamps onsetBorders(iOnset*2-1):(onsetBorders(iOnset*2)+10)];

  removeSamps = [];
  for rOnset = iOnset:nOnsets  
    removeSamps = [removeSamps onsetBorders(rOnset*2-1):onsetBorders(rOnset*2)];
  end
  
  useSamps = setdiff(allSamps,removeSamps);

  complexResonOutNoOnsets = complexResonOut(:,:,useSamps);

  thisOnsetSamps = onsetBorders(iOnset*2-1):onsetBorders(iOnset*2);
  patchSpot = spline(useSamps,complexResonOutNoOnsets,thisOnsetSamps);
  
  complexResonOutPatched(:,:,thisOnsetSamps) = patchSpot;
  
  

  figure(2);
  subplot(2,1,1);
  hold off
  plot(real(squeeze(complexResonOut(1,peakIdxs(1),:))));
  hold on;
  plot(useSamps,real(squeeze(complexResonOutNoOnsets(1,peakIdxs(1),:))),'g.');
  plot(thisOnsetSamps,real(squeeze(patchSpot(1,peakIdxs(1),:))),'m');
  plot([onsetTimes' ; onsetTimes'],repmat([0 ; 60],1,29),'m')  
  
  
  subplot(2,1,2);
  hold off
  plot(real(squeeze(complexResonOutPatched(1,peakIdxs(1),:))));
  hold on;
  plot([onsetTimes' ; onsetTimes'],repmat([0 ; 60],1,29),'m')  

  
  
  
end
  
%trying to patch signal with all onsets missing
allSamps = 1:size(resonOut,3);
removeSamps = [];
for iOnset = 1:nOnsets
  removeSamps = [removeSamps onsetBorders(iOnset*2-1):onsetBorders(iOnset*2)];
end
useSamps = setdiff(allSamps,removeSamps);
testComplexResonOutNoOnsets = complexResonOut(:,:,useSamps);
pp_complexResonOutNoOnsets = spline(useSamps,testComplexResonOutNoOnsets);

testPatched = ppval(pp_complexResonOutNoOnsets,allSamps);

t1 = squeeze(angle(complexResonOutPatched(1,peakIdxs(1),onsetTimes)))
t2= squeeze(angle(testPatched(1,peakIdxs(1),onsetTimes)))
all(t1 == t2)

outData = complexResonOutPatched;