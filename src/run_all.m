addpath(genpath(pwd));

v1 = fullfile('..','data','luce_vp.mp4');
v2 = fullfile('..','data','tennis.mp4');
v3 = fullfile('..','data','DibrisHall.mp4');

tau1=0.08; alpha=0.02; tau2=0.06; W=21;

compareCDAlgo(v1,tau1,alpha,tau2);
compareCDOF(v2,tau1,alpha,tau2,W);
segmentAndTrack(v3,tau1,alpha,tau2);
