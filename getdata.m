function getdata(outputFile,processingDir)

cd(processingDir)

  % GETDATA  Returns data from Nicolet file.
  %
  %   OUT = GETDATA(OBJ, SEGMENT, RANGE, CHIDX) returns data in an nxm array of
  %   doubles where n is the number of datapoints and m is the number
  %   of channels. RANGE is a 1x2 array with the [StartIndex EndIndex]
  %   and CHIDX is a vector of channel indeces.
  
  h=fopen(outputFile);
  info=textscan(h,'%s');
  for i=1:length(info{1})
      isMRN=strfind(info{1}(i),'MRN:');
    if ~isempty(isMRN{1})
        num=char(info{1}(i));
        MRN=num(5:end);
    end
  end

  oldFileName=strcat(MRN,'_header_old.mat');
  newFileName=strcat(MRN,'_header.mat');
 
  try
    oldData=load(oldFileName);
    oldNumSeg=length(oldData.obj.segments);
    oldDuration=oldData.obj.segments(oldNumSeg).duration;
  catch
    return
  end
  newData=load(newFileName);
 fs=newData.obj.chInfo(1).samplingRate;
 newNumSeg=length(newData.obj.segments);
 edgeCase=false;
 
 if oldNumSeg==newNumSeg && oldDuration==newData.obj.segments(newNumSeg).duration
     return
 end
 
 if newNumSeg>oldNumSeg
     edgeCase=true;
 end
 if edgeCase==false
   %  segsToRead=numNewSeg;
     rangesToRead=[oldDuration*fs+1 (newData.obj.segments(newNumSeg).duration-1)*fs];
 else
   %  segsToRead=[newNumSeg newNumSeg-1];
     rangesToRead=[1 (newData.obj.segments(newNumSeg).duration-1)*fs; ...
         oldDuration*fs+1 (newData.obj.segments(newNumSeg-1).duration-1)*fs];
 end
 
 obj=newData.obj;
 if edgeCase
     pulls=2;
 else
     pulls=1;
 end
 % Here we remove the last three "channels" since they are really just IBI,
 % Bursts, and Suppr
 % for now, assue 19 channels for everyone
 %chIdx=1:length(newData.obj.segments(1).chName)-3;
 %chIdx = 1:19;
 % Change of plans: set the indices to where the 18 leads that we want
 % actually are:
 
 usedLeads = {'Fp1','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','P3','P4','T5','O1','O2','T6'};
 chIdx = find(ismember(obj.segments(newNumSeg).chName,usedLeads));
 
 for p=1:pulls
     segment=newNumSeg+1-p;
     range = rangesToRead(p,:);
  % Assert range is 1x2 vector
  assert(length(range) == 2, 'Range is [firstIndex lastIndex]');
  assert(length(segment) == 1, 'Segment must be single value.');

  % Get cumulative sum segments.
  cSumSegments = [0 cumsum([obj.segments.duration])];

  % Reopen .e file.
  h = fopen(obj.fileName,'r','ieee-le');

  % Find sectionID for channels
  lChIdx = length(chIdx);
  sectionIdx = zeros(lChIdx,1);
  for i = 1:lChIdx
    tmp = find(strcmp(num2str(chIdx(i)-1),{obj.sections.tag}),1);
    sectionIdx(i) = obj.sections(tmp).index;
  end

  % Iterate over all requested channels and poplutate array. 
  out = zeros(range(2) - range(1) + 1, lChIdx); 
  for i = 1 : lChIdx

    % Get sampling rate for current channel
    curSF = obj.segments(segment).samplingRate(chIdx(i));
    mult = obj.segments(segment).scale(chIdx(i));

    % Find all sections      
    allSectionIdx = obj.allIndexIDs == sectionIdx(i);
    allSections = find(allSectionIdx);

    % Find relevant sections
    sectionLengths = [obj.index(allSections).sectionL]./2;
    cSectionLengths = [0 cumsum(sectionLengths)];

    skipValues = cSumSegments(segment) * curSF;
    firstSectionForSegment = find(cSectionLengths > skipValues, 1) - 1 ;
    lastSectionForSegment = find(cSectionLengths >= skipValues+curSF*(obj.segments(segment).duration-1),1)-1;


    if isempty(lastSectionForSegment)
      lastSectionForSegment = length(cSectionLengths);
    end

    offsetSectionLengths = cSectionLengths - cSectionLengths(firstSectionForSegment);

    firstSection = find(offsetSectionLengths < range(1) ,1,'last');
    lastSection = find(offsetSectionLengths >= range(2),1)-1;

    if isempty(lastSection)
      lastSection = length(offsetSectionLengths);
    end

    if lastSection > lastSectionForSegment 
      error('Index out of range for current section: %i > %i, on channel: %i', ... 
        range(2), cSectionLengths(lastSectionForSegment+1), chIdx(i));
    end

    useSections = allSections(firstSection: lastSection) ;
    useSectionL = sectionLengths(firstSection: lastSection) ;
% First Partial Segment

    curIdx = 1;
    curSec = obj.index(useSections(1));
    fseek(h, curSec.offset,'bof');

    firstOffset = range(1) - offsetSectionLengths(firstSection);
    lastOffset = min([range(2) useSectionL(1)]);
    lsec = lastOffset-firstOffset + 1;

    fseek(h, (firstOffset-1) * 2,'cof');
    out(1 : lsec,i) = fread(h, lsec, 'int16') * mult;
    curIdx = curIdx +  lsec;

    if length(useSections) > 1
      % Full Segments
      for j = 2: (length(useSections)-1)
        curSec = obj.index(useSections(j));
        fseek(h, curSec.offset,'bof');

        out(curIdx : (curIdx + useSectionL(j) - 1),i) = ...
          fread(h, useSectionL(j), 'int16') * mult;
        curIdx = curIdx +  useSectionL(j);
      end

      % Final Partial Segment
      curSec = obj.index(useSections(end));
      fseek(h, curSec.offset,'bof');
      out(curIdx : end,i) = fread(h, length(out)-curIdx + 1, 'int16') * mult;
    end

  end

  %need to save it here
  date=mat2str(newData.obj.segments(segment).startDate);
  time=mat2str(newData.obj.segments(segment).startTime);
  fileID=fopen(strcat(MRN,'_',num2str(segment),'_',num2str(range(1)),'_',date,'_',time,'.bin'),'w');
  fwrite(fileID,out,'int16');
  fclose(fileID);
  % Close the .e file.
  fclose(h);
 end

end
