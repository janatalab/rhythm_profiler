gainParams.resonatorFreqs = [ 0.250 0.260 0.270 0.280 0.291 0.302 ...
		    0.314 0.326 0.338 0.351 0.365 0.379 0.393 ...
		    0.408 0.424 0.440 0.457 0.475 0.493 0.512 0.532 ...
		    0.552 0.573 0.596 0.618 0.642 0.667 0.693 0.719 ...
		    0.747 0.776 0.805 0.836 0.869 0.902 0.937 0.973 1.010 ...
		    1.049 1.089 1.131 1.175 1.220 1.267 1.316 1.366 1.419 ...
		    1.473 1.530 1.589 1.650 1.713 1.779 1.848 1.919 1.993 ...
		    2.069 2.149 2.231 2.317 2.406 2.499 2.595 2.695 2.799 ...
		    2.906 3.018 3.134 3.255 3.380 3.510 3.645 3.785 3.930 ...
		    4.082 4.239 4.402 4.571 4.747 4.929 5.119 5.316 5.520 ...
		    5.733 5.953 6.182 6.420 6.667 6.923 7.189 7.466 7.753 ...
		    8.051 8.361 8.682 9.016 9.363 9.723 10.097];

gainParams.maxGain = 0.4;
gainParams.minGain = 0.1;
betaGain = resonatorBanks('betaDistribution');
hanningGain = resonatorBanks('partialHanning');

gainParams1 = gainParams;
gainParams1.betaDistribution.alpha = 2;
gainParams1.betaDistribution.beta = 5;
gainVector1 = betaGain(gainParams1);

gainParams2 = gainParams;
gainParams2.betaDistribution.alpha = 2;
gainParams2.betaDistribution.beta = 5;
gainParams2.betaDistribution.flattenAt = 1.25;
gainVector2 = betaGain(gainParams2);

gainParams3 = gainParams;
gainParams3.betaDistribution.alpha = 2;
gainParams3.betaDistribution.beta = 5;
gainParams3.betaDistribution.flattenAt = 1.4;
gainVector3 = betaGain(gainParams3);

gainParams4 = gainParams;
gainParams4.maxFreq = 1.66;
gainVector4 = hanningGain(gainParams4);

figure(1)
cla
func1 = plot(gainParams.resonatorFreqs,gainVector1,'b');
hold on
func2 = plot(gainParams.resonatorFreqs,gainVector2,'m');
hold on
%func3 = plot(gainParams.resonatorFreqs,gainVector3,'g');
%func4 = plot(gainParams.resonatorFreqs,gainVector4,'c');


legend( sprintf('alpha = %.2f, beta = %.2f',...
		gainParams1.betaDistribution.alpha,gainParams1.betaDistribution.beta),...
	sprintf('alpha = %.2f, beta = %.2f, clipped',...
		gainParams2.betaDistribution.alpha,gainParams2.betaDistribution.beta),...
	sprintf('hanning gain'));


%set(gca,'xtick',[0:1:10],
set(gca,'xminortick','on','yminortick','on','ylim',[0.1 0.45]);
xlabel('Resonator Frequency','FontSize',12,'FontWeight','bold');
ylabel('Gain Factor','FontSize',12,'FontWeight','bold');
title(sprintf('Beta Gain Function'),...
      'FontSize',14,'FontWeight','bold');
