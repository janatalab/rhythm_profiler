% creates a repeated series of impulses for feeding through the
% rhythm profiler

QUARTER_NOTE_DUR = 1;

write_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/impulse_calibration';


Fs = 100;
nbits = 16;

sigDur = 20;

%patternList = {[1 0 0 0],[1 0 0 1],[1 0 1 1],[1 0 1 1],[1 0 1 1  1 0 0 1],...
%	       [1 0 1 1  1 1 0 1]};
%sixteenthDurList = [0.150 0.125 0.1];
%numDur = length(sixteenthDurList);

patternList = {[1 0 0 0]};
numFiles = 20;
quarterDurList = logspace2(log2(.2),log2(2),numFiles);
numDur = length(quarterDurList);


for iDur = 1:numDur

  if(QUARTER_NOTE_DUR)
    sixteenthDur = quarterDurList(iDur)./4;
  else
    sixteenthDur = sixteenthDurList(iDur);
  end
  
  sixteenthDurSamps = round(sixteenthDur.*Fs);
  
  for iPattern = 1:length(patternList)
    
    pattern = patternList{iPattern};
    patternDur = length(pattern).*sixteenthDur;
    patternDurSamps = round(patternDur.*Fs);
    patternSig = zeros(patternDurSamps,1);
    patternSig((find(pattern)-1).*sixteenthDurSamps + 1) = 1;
    
    sig = zeros(sigDur.*Fs,1);
    timeVec = 1:length(sig);
    sig(find(patternSig(mod(timeVec,length(patternSig))+1))) = 0.99;

    signum = (iDur - 1) * length(patternList) + iPattern;
    
    wavwrite(sig,Fs,nbits,fullfile(write_dir,[num2str(signum) '_rptest.wav']));
    
  end
end
