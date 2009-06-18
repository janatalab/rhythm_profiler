function onsetExpectMtx = rp_predictCurrentOutput(varargin)
% removes the effects of current onsets on the resonator Outputs
%
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
% Stefan Tomic 3/17/2009

for iArg = 1:2:nargin
  switch(varargin{iArg})
   case 'resonBankOut'
    resonBankOut = varargin{iArg+1};
   case 'onsetTimesSamps'
    onsetTimesSamps = varargin{iArg+1};
   case 'onsetBorders'
    onsetBorders = varargin{iArg+1};
   case 'BList'
    BList =  varargin{iArg+1};
   case 'AList'
    AList = varargin{iArg+1};
   case 'params'
    params = varargin{iArg+1};
  end
end


% we shouldn't have to check time lims here anymore
% since the rhythm profile should have used the time lim
% at the first stage of processing
%timeLimSecs = params.timeLimSecs;
%timeLimSamps = round(timeLimSecs*Fs);


nOnsets = length(onsetTimesSamps);
fid =1;
Fs = params.Fs;

fprintf(fid,['\nCalculating reson filter predictor, assuming on no' ...
	     ' future input. Onset # ']);

for iOnset = 1:nOnsets
    
  if(mod(iOnset-1,10) == 0)
    fprintf(fid,' %d ',iOnset);
  end

  leftOnsetBorder = onsetBorders(iOnset*2-1);  
  resonBankOutNoOnset = resonBankOut(:,[1:leftOnsetBorder-1]);
  
  if(isempty(resonBankOutNoOnset))
    expectValue = 0;
  else
    
    BAll = [BList{:}];
    AAll = [AList{:}];
    
    b0List = BAll(1:3:end)';
    b1List = BAll(2:3:end)';
    b2List = BAll(3:3:end)';
    
    a0List = AAll(1:3:end)';
    a1List = AAll(2:3:end)';
    a2List = AAll(3:3:end)';
      
    %assuming that current input sample and two samples ago are
    %both zero, since we want a prediction value based on no input.
    x0 = 0;
    x2 = 0;
      
    y1List = resonBankOutNoOnset(:,leftOnsetBorder-1);
    
    if(onsetTimesSamps(iOnset) > 2)
      y2List = resonBankOutNoOnset(:,leftOnsetBorder-2);
    else
      y2List = zeros(size(resonBankOut,1),1);
    end
       
    switch(params.resonatorBank.method)
     case 'reson_z'
      
      %look nSamples into the future. We need to go into the
      %future so that the hilbert transform correctly
      %approximates the current phase.
      nSamples = round(params.temporalExpect.predictSec .* Fs);
      expectValue = [];
      expectValueHil = [];
  
      for iSample = 1:nSamples
	
	expectValue(:,iSample) = (-a1List.*y1List -a2List.*y2List)./a0List;
	
	y2List = y1List;
	y1List = expectValue(:,iSample);
	
      end
      
      expectSeries = [resonBankOutNoOnset expectValue];
      hilbertExpectSeries = hilbert(expectSeries')';
      onsetExpectMtx(:,iOnset) = hilbertExpectSeries(:,onsetTimesSamps(iOnset));
     
     otherwise
      error('This function currently only supports reson_z filters.');
      
    end
  end

end % for iOnset

%if there was no energy in this frame (mean rms is 0), this results
%in a NaN. So just setting this to 0.
onsetExpectMtx(isnan(onsetExpectMtx)) = 0;

fprintf(fid,'\n');


