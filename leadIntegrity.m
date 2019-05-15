function leadIntegrity(processingDir)

cd(processingDir)


%if you don't have an MRN yet, check every ten seconds to see if one has
%been generated and if so grab it
foundMRN=false;
tries=0;
while ~foundMRN && tries < 3
    try 
        h=fopen('output.txt');
        info=textscan(h,'%s');
        for i=1:length(info{1})
             isMRN=strfind(info{1}(i),'MRN:');
             if ~isempty(isMRN{1})
                num=char(info{1}(i));
                MRN=num(5:end);
                foundMRN=true;
             end
        end
        fclose(h);
    catch
        tries = tries + 1;
        pause(10);
    end
end
if tries==3
    return
end

if ~exist([MRN '_read'],'dir')
    mkdir([MRN '_read']);
end
gotHeader=false;
tries = 0;
while ~gotHeader && tries<10
    try
        info=load([MRN '_header.mat']);
        gotHeader=true;
    catch
        tries=tries+1;
        pause(2);
    end
end
if tries==10
    return
end
usedLeads = {'Fp1','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','P3','P4','T5','O1','O2','T6'};
numChan = sum(ismember(info.obj.segments(1).chName,usedLeads));
fs=info.obj.chInfo(1).samplingRate;
chNames=info.obj.segments(1).chName;
chIdx = find(ismember(chNames,usedLeads));
%might have to use this header to get the ID/location of
%the electrodes to know which are on which side of the head

try
    load([MRN '_buffer.mat']);
catch
    % Define buffer in terms of sampling frequency
    buffer = zeros(60*60*fs,numChan);
end
%postSent=false;
tries=0;
while tries<5
    tries = tries+1;
    d=dir([MRN '*.bin']);

    if isempty(d)
        break
    end
    
    %matlab will sort the names appropriately so we just grab the top
    %(oldest) one
    
    binName=d.name;   
    fileID=fopen(binName);
    incomingData=fread(fileID,'int16');
    fclose(fileID);
    movefile(binName,strcat(MRN,'_read/',binName));
    incomingData=reshape(incomingData,[],numChan);
    %so now we have the data. shift the buffer, add this to the end,
    % and then move the file to the read directory

    inDP=size(incomingData,1);

    if inDP >= size(buffer,1)
        % if incoming data is bigger just save what fits
        buffer = incomingData(end-size(buffer,1)+1:end,:);
    else
        buffer(1:end-inDP,:)=buffer(inDP+1:end,:);
        buffer(end-inDP+1:end,:)=incomingData;
    end
    
    % load the existing offlead data
    try 
        load([MRN '_lastOff.mat']);
    catch
        lastOff=zeros(1,numChan);
    end
 %% this is where we detect a disconnected lead:
    % just use the whole buffer
    featTrace=cell(1,numChan);
    meds = zeros(1,numChan);
    LLfn = @(x)sum(abs(diff(x)));
    for chan=1:numChan
        featTrace{chan}= MovingWinFeats(buffer(:,chan),fs,30,30,LLfn);
        meds(chan)=median(featTrace{chan});
    end
    rf = cell2mat(featTrace);
    thr = prctile(rf(:),75) + 2*iqr(rf(:));
    %offLeads=meds>(mean(meds)+3*std(meds));
    offLeads=meds>thr;
    postTime=now;
    
    % Here, add a detector that fires if all leads are off
    %this is how we used to do it but it stinks. We can probably still use
    %it to detect if all leads are off. We will just look at the max
    %amplitude and 60 hz bandpower over the last 5 minutes to see what is
    %currently off. Will need testing in unit to determine if these
    %parameters are appropriate.
    window = fs*60*5;
    allOff = true;
    for chan=1:numChan
        maxAmp=max(abs(buffer(end-window:end,chan)));
        bandPow=bandpower(buffer(end-window:end,chan),fs,[59.9 60.1]);
        
        if maxAmp<500 || bandPow < 1000
            allOff = false;
            break
        end
    end
    if allOff
        offLeads(:)=1;
    end
 %%  
    % post if we need to
    window = fs*60*10; %use a 10 minute window for the image
    if sum(postTime-lastOff(offLeads==1)>30/60/24)>0
    %if sum(dot(offLeads,shouldSend))>=1
        offNames=strjoin(chNames(chIdx(offLeads==1)));
        f=figure('Visible','off');
        x = 0:1/60/fs:10;
        plot(x,buffer(end-window:end,:) + repmat(1:numChan,window+1,1)*-250)
        set(gca,'Ytick',fliplr((1:numChan)*-250));
        set(gca,'YTickLabel',fliplr(chNames(chIdx)));
        xlabel('Time (Minutes)')
        saveas(f,'lastpost.png','png');
        close(f);
        imagePath = [pwd '/lastpost.png'];
       % reply = unix(['LD_LIBRARY_PATH="";curl -k -H ''Content-Type: application/json'' --data ''{"clientId":"cdd6ac8b-560b-4ef4-971b-49302e519c9f","patientMrn":"' MRN '","patientMrnFacility":"HUP","type":"disconnection","detail":"The signal from the following EEG leads is bad: ' offNames '","attachmentType":"image/png","attachmentData":fs.readFileSync(' pwd '/lastpost.png' ')}'' https://api.agent.uphs.upenn.edu/v1/events']);
        commandStr = ['python /home/sbaldassano/scripts/jsonPost.py ' MRN ' ''' offNames ''' ' imagePath];
        status = system(commandStr);
        if status ~= 0
            fprintf('Posting failed\n');
        end
        name=strsplit(binName,{'_','[',']'});
        date=strsplit(char(name(4)),' ');
        startTime=strsplit(char(name(5)),' ');
        startDN=datenum(str2num(date{1}),str2num(date{2}),str2num(date{3}),str2num(startTime{1}),str2num(startTime{2}),str2num(startTime{3}));
        timeSince=(str2num(name{3})+inDP)/fs/60/60/24;
        callTime=startDN+timeSince;
        fprintf(['Post sent at ' datestr(callTime) ' with bad leads: ' offNames '\n']);
       
    end
    lastOff(offLeads==1)=postTime;
    save([MRN '_lastOff.mat'],'lastOff','offLeads');

end 

save([MRN '_buffer.mat'],'buffer')
end


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

