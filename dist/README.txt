Copyright (c) 2008 The Regents of the University of California
All Rights Reserved


DESCRIPTION

This distribution contains a series of Matlab functions for performing rhythm based analyses of musical audio signals and 
MIDI recordings of tapping responses. The algorithm, called BTB (Beyond the Beat), is based on the work of 
Scheirer (1996) and includes some elements of the model by Klapuri et al. (2006). It was developed by Stefan Tomic and 
Petr Janata. The most significant difference between our model and these other two models is the use of reson filters 
instead of comb filters for inspecting periodicities in the onset pattern of the signal. We inspect the RMS of all of 
the filter outputs to characterize the metric structure of stimuli and responses.

Further information on the algorithm and on how to interpret the model's output can be found at 
http://atonal.ucdavis.edu/projects/btb. 

This README primarily serves to list the prerequisites, describe the organization of the matlab code, and provide
instructions on how to install and run BTB.


SUBDIRECTORIES

event_objects -   functions for initializing data structures used to describe auditory or MIDI events.

midi -	        functions for reading MIDI files.

jobs -	        wrapper scripts for running the algorithm and producing plots. The only file currently stored here is btb.m.  
                  Edit btb.m to set the path of your audio or midi files and then call it to run the algorithm.

proc -            functions for processing with the model. The entry point to the model is ipem_proc_series, 
	        which contains all the basic procedures in our research lab that involve the IPEM toolbox. 
	        The BTB algorithm only uses the ANI and RP (rhythm profiler) processes. ipem_proc_series.m calls 
	        rhythm_profiler.m, which handles all of the processing stages of the BTB algorithm after ANI 
	        processing. The other functions in this directory generally supplement the use of these two functions.

proc/rp_modules - functions for processing signals through the resonator banks (resonatorBanks.m) and for 
	        calculating the RMS of the resonator bank output (resonatorEnergy.m).

plots -	        functions for plotting resonator bank outputs, RMS of the resonator bank outputs (periodicity surfaces), 
                  the average periodicity surface (APS), and the mean periodicity profile (MPP).

utils -           miscellaneous utilities

Some of the functions reference Ensemble, which is an experiment management and presentation system used in our lab.
Ensemble is not required, however, to use BTB.


PREREQUISITES

BTB requires installation of the IPEM Toolbox. It can be obtained at http://www.ipem.ugent.be/Toolbox. 
Particularly, the IPEMCalcANI function must be working in order to process audio files with the model.

If processing mp3 files, "mp3read" is required. This may be downloaded at:
http://labrosa.ee.columbia.edu/matlab/mp3read.html


INSTALLATION

Copy the btb directory to an appropriate location for your matlab installation. Add this directory, and all subdirectories 
to your Matlab path. This can be easily accomplished by adding the following line to your startup.m file:

path(path,genpath(<path_to_btb>));

where <path_to_btb> is the absolute path to the btb directory.


MIDI FILES

A MIDI file reader written in Java, "Midi2tr.java", and a second java class, "TrackInfo.java", located in the 
midi subdirectory must be compiled and configured for Matlab in order to use BTB with MIDI files. If you don't 
have a Java compiler installed on your system, it can be obtained by downloading the Java Standard Edition (Java SE) at java.sun.com. 
The current version at the time of this writing is JDK 6 Update 4. To compile Midi2tr.java and TrackInfo.java, simply go to the midi
directory and type the following at a command line (assuming that javac is in your path):

javac Midi2tr.java TrackInfo.java

This should create files "Midi2tr.class" and "TrackInfo.class" in the midi directory. In order to use the Java classes in Matlab,
the path of the midi directory (e.g. /home/username/btb/midi) must be added to Matlab's classpath.txt, which typically resides in 
<path to Matlab application>/toolbox/local.

The MIDI reader was written in java to speed up the process of reading very large MIDI files.  Alternately, you may install the 
MIDI Toolbox and replace the line in plot_dir_rhythm_profile.m:
tr = javamidi2tr(thisLocation);

with the following:
tr.nmat = readmidi(thisLocation);


The MIDI Toolbox may be obtained from:
http://www.jyu.fi/hum/laitokset/musiikki/en/research/coe/materials/miditoolbox/


HOW TO RUN
Open btb.m and set rp_proc_dir to the directory containing the audio or midi files you wish to analyze. Then set 
input_file_pattern to the file pattern of your input (e.g. '*.wav', '*.mid', or '*.mp3').

When BTB is run, it will produce subdirectories for each sound file under rp_proc_dir which contain data structures 
for the model output (rp), and the output of the Auditory Peripheral Module (ani). Periodicity surface and average
periodicity surface (APS) plots are saved as postscript files.


CONTACT
If you have any questions regarding the algorithm or code, please feel free to email Stefan Tomic at sttomic@ucdavis.edu.

Stefan Tomic
Center for Mind and Brain
University of California, Davis
07/24/2008
