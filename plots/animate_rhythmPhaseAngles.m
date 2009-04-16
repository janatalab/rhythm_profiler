function outData = animate_rhythmPhaseAngles(inData,params)
%
% quick animation of expectancy phase angles. This might turn into
% a more fleshed out function
%
% S.T. 4/1/09

params.frameRate = 60;
params.frameDir = '/data2/groove/rmgc/animations/fh1';

rp = inData{1};
rp = ensemble_datastruct2tree(rp);
Fs = rp.Fs;

expectationData = rp.expectationError;
onsetExpectMtx = expectationData.onsetExpectMtx;
onsetTimesSamps = expectationData.onsetTimesSamps;
onsetTimesSecs = onsetTimesSamps/Fs;


frameRate = params.frameRate;
nSamples = size(rp.resonatorOut,3);
nBanks = size(rp.resonatorOut,1);

timeSeries = 1:nSamples;
nFrames = floor(nSamples/Fs*frameRate);

summedExpectationData = squeeze(sum(onsetExpectMtx,2));
maxRadius = (max(max(abs(summedExpectationData))) + 1);

figure(1);
set(1,'position',[100 100 768 576]); %[100 100 1400 1050]);
frameInfoH = axes('position',[.8 0 .2 .05]);

%setting up for first frame and frames before any onsets
for iBank = 1:nBanks+1
  %subplot(2,3,iBank);
  
  axesBottom = 0.5 - floor(iBank/4)*0.5;
  axH(iBank) = axes('position',[.33*(mod(iBank-1,3)) axesBottom .33 .5]);
  axis(axH(iBank),'square');
  compass(0);
  
  if(iBank == nBanks + 1)
    extentRadius = maxRadius;
  else
    extentRadius = maxRadius/4;
  end
  
  extentVectorH = compass(complex(extentRadius*cos(1/100*pi),extentRadius*sin(1/100*pi)),'w');
  set(extentVectorH,'visible','off');
  camroll(90);
end

sumVectors = zeros(5,1);
sumAllVector = 0;

for iFrame = 1:nFrames
  
  frameStartTime = iFrame/frameRate;
  frameEndTime = (iFrame+1)/frameRate;
  
  onsetTimeIdxsThisFrame = find(onsetTimesSecs >= frameStartTime & onsetTimesSecs < frameEndTime);
  if(~isempty(onsetTimeIdxsThisFrame))

    %find the last onset within the frame time window that is not zero
    %onsetNum = onsetTimeIdxsThisFrame(find(summedExpectationData(iBank,onsetTimeIdxsThisFrame),1,'last'));
    onsetNum = onsetTimeIdxsThisFrame(end);
    
    
    if(~isempty(onsetNum))
      for iBank = 1:nBanks
      
	sumVectors = sum(squeeze(onsetExpectMtx(:,:,onsetNum)),2);
      
	%only overwrite the plot for the current bank if it has changed
	if(any(abs(sumVectors) >= 0.1))	
	  figure(1);
	  axes(axH(iBank));  
	  hold off;
	  extentRadius = maxRadius/4;
	  extentVectorH = compass(complex(extentRadius*cos(1/50*pi),extentRadius*sin(1/50*pi)),'w');
	  set(extentVectorH,'visible','off');
	  hold on;
	  compass(sumVectors(iBank),'r');
	  compass(onsetExpectMtx(iBank,:,onsetNum));
	  xlim = get(gca,'xlim');
	  ylim = get(gca,'ylim');
	  text(xlim(1),ylim(2),sprintf('%d',iBank),'fontweight','bold');
	  camroll(90);
	end
      
      end %for
    end %if(~isempty(onsetNum))
    
  else
    %compass(0);
    %camroll(90);
    sumVectors = zeros(5,1);
  end
   
  if(abs(sum(sumVectors)) >= 0.3)
    sumAllVector = sum(sumVectors);
  end  
  
  axes(axH(6));
  axis square;
  hold off;
  extentRadius = maxRadius;
  extentVectorH = compass(complex(extentRadius*cos(1/50*pi),extentRadius*sin(1/50*pi)),'w');
  set(extentVectorH,'visible','off');
  hold on; 
  compass(sumAllVector,'m');
 
  xlim = get(gca,'xlim');
  ylim = get(gca,'ylim');
  text(xlim(1),ylim(2),'Sum','fontweight','bold');
  camroll(90);
  
  axes(frameInfoH);
  cla;
  set(gca,'visible','off');
  text(0,.2,sprintf('Frame # %d',iFrame),'fontsize',8);
  text(.5,.2,sprintf('Time: %.2f',frameStartTime),'fontsize',8);
  
  
  
  
  fname = fullfile(params.frameDir,sprintf('frame%0.4d',iFrame));
  print(fname,'-djpeg');
  
  
  
end

outData = [];
