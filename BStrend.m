function BStrend(processingDir)

cd(processingDir)

h=fopen('output.txt');
info=textscan(h,'%s');
for i=1:length(info{1})
    isMRN=strfind(info{1}(i),'MRN:');
    if ~isempty(isMRN{1})
        num=char(info{1}(i));
        MRN=num(5:end);
    end
end

try
    load([MRN '_lastOff.mat']);
catch
    offLeads = zeros(18,1);
end

if min(offLeads)==1
    return
end

load([MRN '_state.mat']);
if state == 0
    return
end

load([MRN '_buffer.mat']);

info=load([MRN '_header.mat']);
fs=info.obj.chInfo(1).samplingRate;
fprintf('State is 1. Checking to see if we should train centroids.\n');
if ~exist([MRN '_centroids.mat'],'file');
    % train the centroids if it has been at least 30 minutes since we have
    % been suppressed and there are no leads off.
    
    if (now-stateTime)>=30/60/24  && sum(offLeads)==0
        fprintf('Conditions met. Training.\n');
        % now we train
        numChan = 18;
        
        buffWin = 30*60*fs;
        curData = buffer(end-buffWin+1:end,:);
        
        stdTrace = [];
        for chan = 1:numChan
            stdTrace(:,chan) = MovingWinFeats(curData(:,chan),fs,0.125,0.125,@std);
        end
        
        numClust = 2;
        [~, C] = kmeans(stdTrace,numClust);

        centDist = zeros(numClust,1);
        for i = 1:numClust
            centDist(i) = sum(C(i,:).^2);
        end

        suppIdx = find(centDist == min(centDist));
        fprintf('Trained. Saving now.\n');
        save([MRN '_centroids.mat'],'C','suppIdx','numClust');
    else
        if sum(offLeads)~=0
            fprintf('There is at least one bad lead. Not trained.\n');
        else
            fprintf('Has not been suppressed long enough. Not trained.\n');
        end
        return
    end
else
    load([MRN '_centroids.mat']);
end


%%
% Part 3: Now we know we are in burst suppression and we have trained
% centroids. Use these centroids to assign incoming data to burst or
% suppression and make the trend.

%try 
%   load([MRN '_BSRtrend.mat']);
%catch
%    BSRtrend = [];
%end

% for now we will just show the trends over the last hour (so we will just
% use the whole buffer)
fprintf('Centroids loaded. Generating trend over last hour.\n');
BSRtrend = zeros(6,1);
euclidDist = @(x,y) sqrt(sum( (x-y).^2));

for b = 1:6
    startIdx = 1 + (b-1)*10*60*fs;
    curData = buffer(startIdx:min(startIdx+10*60*fs,size(buffer,1)),:);

    stdTrace = [];
    for chan = 1:numChan
        stdTrace(:,chan) = MovingWinFeats(curData(:,chan),fs,0.125,0.125,@std);
    end
    supps = zeros(size(stdTrace,1),1);
    
    
    for i = 1:size(stdTrace,1)
        dists = zeros(numClust,1);
        for c = 1:numClust
            dists(c) = euclidDist(stdTrace(i,~offLeads),C(c,~offLeads));
        end
        if find(dists == min(dists)) == suppIdx
            supps(i) = 1;
        end
    end
    
    BSRtrend(b) = sum(supps)/length(supps);
end

fprintf('Trend analysis OK. Last BSR is %f. About to post.\n', BSRtrend(end));

f = figure('Visible','off');
x = 5:10:55;
plot(x,fliplr(BSRtrend),'o-');
set(gca,'XDir','reverse')
ylim([0 1]);
xlabel('Time (Minutes ago)');
ylabel('Burst-Suppression Ratio (1=Suppressed)');
saveas(f,'bst_lastpost.png','png');
close(f)
imagePath = [pwd '/bst_lastpost.png'];
commandStr = ['python /home/sbaldassano/scripts/bs_jsonPost.py ' MRN ' 1 ' num2str(BSRtrend(end),2) ' ' imagePath];
status = system(commandStr);
if status ~= 0
    fprintf('Posting failed\n');
else
    fprintf('Posting succeeded\n');
end
% post with the latest BSR and a picutre of the trend over the last hour

end
%%
% include moving win funct for later.
function feat = MovingWinFeats(x,fs,winLen,winDisp,featFn)

% Determine the number of windows
NumWins=@(xLen,fs,winLen,winDisp)(floor((xLen/fs-winLen)/winDisp)+1);
wins=NumWins(length(x),fs,winLen,winDisp);
feat = zeros(1, wins);

% For each window, determine the datapoints in that window and evaluate
% them using the specified feature function
for i = 1:wins
    offSet = (i-1)*winDisp*fs;
    endPoint = offSet+winLen*fs;
    feat(i) = featFn(x(1+offSet:endPoint));
end
end