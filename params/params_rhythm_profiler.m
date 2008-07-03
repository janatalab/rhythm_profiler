function params = params_rhythm_profiler
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved.
%
% Author:
% Stefan Tomic

%Number of ANI banks to sum
params.sumAdjacentBands = 8;

%RMS Parameters
params.ipemRMSMethod = 1;
params.rmsFs = 100;
params.rmsFrameWidth = .050;

%Entropy Parameters
params.entropy_frame_size = 2.52;
params.entropy_hop_size = 0.25; %hop size in seconds for entropy calculation

%Resonator Bank Parameters
params.resonatorBankParams.method = 'comb';
params.resonatorBankParams.freqLimits = [0.5 20];
params.resonatorBankParams.Fs = params.rmsFs;
switch(params.resonatorBankParams.method)
 case 'reson'
  params.resonatorBankParams.gain = .4;
  params.resonatorBankParams.bandwidth = .12;
 case 'comb'
  params.resonatorBankParams.halfEnergyTimeSecs = 1.5;  
 otherwise
  error('Unrecognized resonator bank method in params.');
end

%Reson Energy calculation/Tempo Calculation
params.resonatorEnergyParams.windowSecs = 2;


