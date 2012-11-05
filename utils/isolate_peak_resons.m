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

% get freq peak info from stimRP
stimRP_cols = set_var_col_const(stimRP_st.vars);
stimResonFreqs = stimRP_st.data{stimRP_cols.resonatorFreqs};
stimPeakInfo = stimRP_st.data{stimRP_cols.peakInfo};
stimPeak_cols = set_var_col_const(stimPeakInfo.vars);
stimPeak_freqs = stimPeakInfo.data{stimPeak_cols.peakFreq};
npeaks = length(stimPeak_freqs);
stimPeakIdx = stimPeakInfo.data{stimPeak_cols.peakIdxs};
stimPeakWidth = stimPeakInfo.data{stimPeak_cols.width}; 

% use peak width to determine whether more than one resonator should be
% included for each peak. Useful if width of some peaks overlap multiple 
% resonators.

add_res_counter = 0;
for ipeak = 1:npeaks
    curr_peakFreq = stimPeak_freqs(ipeak);
    curr_peakWidth = stimPeakWidth(ipeak);
    resonFreqIdx = find(stimResonFreqs==curr_peakFreq);
    if ~ismember(curr_peakFreq,min(stimResonFreqs)) && stimPeakWidth(ipeak)~=0
        peakWidthBoundary_left = curr_peakFreq-(curr_peakWidth/2);
        if peakWidthBoundary_left < stimResonFreqs(resonFreqIdx-1)
            add_res_counter = add_res_counter+1;
            add_resonIdx(add_res_counter) = resonFreqIdx-1;
        end
    end
    if ~ismember(curr_peakFreq,max(stimResonFreqs)) && stimPeakWidth(ipeak)~=0
        peakWidthBoundary_right = curr_peakFreq+(curr_peakWidth/2);
        if peakWidthBoundary_right > stimResonFreqs(resonFreqIdx+1)
            add_res_counter = add_res_counter+1;
            add_resonIdx(add_res_counter) = resonFreqIdx+1;
        end
    end
end

% Indices of all resons to be isolated
if ~isempty(add_resonIdx)
    reson_Idx = sort(cat(1,stimPeakIdx,add_resonIdx'));
end

% Now, reduce target average periodicity matrix down to reson_Idx
% resonators



outData = [];

return