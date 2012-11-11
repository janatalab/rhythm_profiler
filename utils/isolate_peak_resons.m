function outData = isolate_peak_resons(varargin)

% outData = isolate_RP_resons('stimRP',stimRP_st,'targetRP',targRP)
% 
% Isolates frequency bands from reson energy matrix that correspond to a set 
% of frequency peaks, as produced by Rhythm Profiler. Allows one to assess 
% energy at periodicities corresponding to a stimulus' metric structure, 
% ignoring energy in non-metric frequencies. 
%
% Input
%   'stimRP': rp struct for rhythm profile from which peaks will be extracted
%   'targetRP': rp struct that will be pared down based on stimRP peaks
%
% Output
%   outData: reson energy matrix with only indexed resonators remaining
%
% Oct 28, 2012 BH

for iarg = 1:2:length(varargin)
  
  switch(varargin{iarg})
   case 'stimRP'
    stimRP_st = varargin{iarg+1};
   case 'targetRP'
    targRP = varargin{iarg+1};
  end
 
end

% Get freq peak info from stimRP
stimRP_cols = set_var_col_const(stimRP_st.vars);
stimResonFreqs = stimRP_st.data{stimRP_cols.resonatorFreqs};
stimPeakInfo = stimRP_st.data{stimRP_cols.peakInfo};
stimPeak_cols = set_var_col_const(stimPeakInfo.vars);
stimPeak_freqs = stimPeakInfo.data{stimPeak_cols.peakFreq};
npeaks = length(stimPeak_freqs);
stimPeakIdx = stimPeakInfo.data{stimPeak_cols.peakIdxs};
stimPeakWidth = stimPeakInfo.data{stimPeak_cols.width}; 

% Use peak width to determine whether more than one resonator should be
% included for each peak. Useful if width of some peaks overlap multiple 
% resonators.

isolateResonIdxs = [];
for ipeak = 1:npeaks
    curr_peakFreq = stimPeak_freqs(ipeak);
    curr_peakWidth = stimPeakWidth(ipeak);
    peakRange = [-1 1]*curr_peakWidth/2 + curr_peakFreq;
    idxs = find(stimResonFreqs <= min(peakRange),1,'last'):find(stimResonFreqs >= max(peakRange),1,'first');
    isolateResonIdxs = union(isolateResonIdxs, idxs);
end

% Now, reduce target average periodicity surface matrix down to reson_Idx
% resonators

targRP_cols = set_var_col_const(targRP.vars);
targResEnergy = targRP.data{targRP_cols.resonatorEnergy};
reduced_targResEnergy = zeros(size(targResEnergy));
reduced_targResEnergy(isolateResonIdxs,:) = targResEnergy(isolateResonIdxs,:); % zeroing out rows corresponding to non-peak resons rather than removing rows altogether


outData = reduced_targResEnergy;

return