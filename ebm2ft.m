function [data] = ebm2ft(subj)
%EBM2FT read embla folder and transform into fieldtrip dataset
% Use as:
%   [data] = ebm2ft(subj)
% where subj is the number of the subject

% 11/10/26 created

epdur = 30;
scaling = 1e6; % V into uV

%-------------------------------------%
%-dir and files
recdir = '/data/projects/hgse/BLIND/';
channels = {'Fpz' 'Cz'};

sdir = sprintf('%s%02.f/', recdir, subj);
%-------------------------------------%

%-------------------------------------%
%-read events
evt = readevents([sdir 'Events.txt']);
art = readevents([sdir 'Eventa.txt']);

if ~isempty(setdiff([evt.timestamp], [art.timestamp]))
  warning('time stamps between Events.txt and Eventa.txt do not match')
end
%-------------------------------------%

%-------------------------------------%
%-read data for each channels
for c = 1:numel(channels)
  
  chanfile = dir([sdir channels{c} '*.ebm']);
  if ~isempty(chanfile)
    [dat{c}, hdr] = ebmread( [sdir chanfile(1).name]);
  end
end

fs = hdr.samplingrate;
%-------------------------------------%

%-------------------------------------%
%-create fieldtrip data
data = [];
data.fsample = fs;

for c = 1:numel(dat)
  data.label{c,1} = channels{c};
end

%-----------------%
%-trial loop
for i = 1:numel(evt.state)
  
  offsec = ceil(date2sec( evt.timestamp(i) - hdr.starttime)); % offset in seconds
  begsmp = offsec * hdr.samplingrate + 1;
  endsmp = (offsec + epdur) * hdr.samplingrate;

  for c = 1:numel(dat)
    data.trial{i}(c, :) = dat{c}(begsmp:endsmp) * scaling;
  end
  data.time{i} = offsec + (0:1/fs: (epdur-1/fs));
  
  data.sampleinfo(i, :) = [begsmp endsmp];
  data.trialinfo(i, :) = [evt.timestamp(i) evt.state(i) art.state(i)];
  
end
%-----------------%
%-------------------------------------%

function [sec] = date2sec(fulldate)
sec = 24*60*60*fulldate;