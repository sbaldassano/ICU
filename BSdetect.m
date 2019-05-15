function BSdetect(processingDir)

cd(processingDir)

% get the current MRN
h=fopen('output.txt');
info=textscan(h,'%s');
for i=1:length(info{1})
    isMRN=strfind(info{1}(i),'MRN:');
    if ~isempty(isMRN{1})
        num=char(info{1}(i));
        MRN=num(5:end);
    end
end

% load the header info to get fs
% load the last hour saved in buffer
info=load([MRN '_header.mat']);
fs=info.obj.chInfo(1).samplingRate;
chNames=info.obj.segments(1).chName;
usedLeads = {'Fp1','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','P3','P4','T5','O1','O2','T6'};
chIdx = find(ismember(chNames,usedLeads));
numChan = 18;

try
    load([MRN '_lastOff.mat']);
catch
    offLeads = zeros(18,1);
end

if min(offLeads)==1
    return
end

inData = load([MRN '_buffer.mat']);
buffer = inData.buffer;

% get the last 15 minutes to see if we are suppressed
buffWin = 15*60*fs;
curData = buffer(end-buffWin+1:end,~offLeads);
% We will filter this up front and downsample for analysis ifneeded
downsamp = ceil(fs/256);
fs = fs/downsamp;
curData = downsample(curData,downsamp);
FcurData = sgolayfilt(curData,3,2*floor(fs/8/2)+1);

winLen = 2*fs;
numWins = floor(size(FcurData,1)/winLen);
avgDers = [];
%  Use 2 second windows and see if each qualifies as suppression using the
%  1st derivative test
for w = 1:numWins-1
    startIdx = 1+(w-1)*winLen;
    clip = FcurData(startIdx:startIdx+winLen,:);

    der = diff(clip)./(1/fs);

    avgDers = [avgDers; mean2(abs(der))];
end
% remove artifact extreme outliers
avgDers(avgDers > 1000) = [];

perSup = sum(avgDers < 100)/length(avgDers);

isSuppressed = 0;
if perSup >= 0.33
    isSuppressed = 1;
end

% We need to make sure that we don't call suppression if the EEG just
% flatlines, or if we just started recording and most of the buffer is
% zeros. We will say that we are not suppressed if over 1/4 of the values
% in the current data are 0. 

if sum(curData(:)==0)/numel(curData) >= 0.25
    isSuppressed = 0;
end

% here we need to load what the previous state was, and send a notification
% if the state has changed. 

% load the saved state
try
    load([MRN '_state.mat']);
catch
    state = 0;
    stateTime = now;
    save([MRN '_state.mat'],'state','stateTime');
end
save([MRN '_bsTraining.mat'],'avgDers');
fprintf('BSdetect ran OK. The current state is %g and the old state was %g\n', isSuppressed,state);

% Make a figure for posting if something has changed
if state ~= isSuppressed
    state = isSuppressed;
    stateTime = now;
    fprintf('The state has changed at %g\n',stateTime);
    
    f=figure('Visible','off');
    x = 0:1/60/fs:15;
    plot(x,curData + repmat(1:numChan,size(curData,1),1)*-250)
    set(gca,'Ytick',fliplr((1:numChan)*-250));
    set(gca,'YTickLabel',fliplr(chNames(chIdx)));
    xlabel('Time (Minutes)')
    saveas(f,'bs_lastpost.png','png');
    close(f);
    imagePath = [pwd '/bs_lastpost.png'];
    fprintf('Figure saved. Trying to post\n');
    commandStr = ['python /home/sbaldassano/scripts/bs_jsonPost.py ' MRN ' 0 ' num2str(state) ' ' imagePath];
    status = system(commandStr);
    if status ~= 0
        fprintf('Posting failed\n');
    else
        fprintf('Posting success\n');
    end
    
    % save the new state as well as the current time
    save([MRN '_state.mat'],'state','stateTime');
end

end