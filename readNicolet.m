unction obj = readNicolet(filename,processingDir)

cd(processingDir)

   obj = struct();
   obj.useTSinfoIdx=1;
   obj.LABELSIZE=32;
   obj.TSLABELSIZE=64;
   obj.UNITSIZE=16;
   obj.ITEMNAMESIZE=64;

  h = fopen(filename,'rb','ieee-le');

  [folder, ~, ext] = fileparts(filename);
  assert(strcmp(ext,'.e'), 'File extention must be .e');
  if isempty(folder)
    filename = fullfile(pwd,filename);
  end

  obj.fileName = filename;
  % Get init 
  misc1 = fread(h,5, 'uint32'); %#ok<NASGU>
  unknown = fread(h,1,'uint32'); %#ok<NASGU>
  indexIdx = fread(h,1,'uint32');
% Get TAGS structure and Channel IDS
  fseek(h, 172,'bof');
  nrTags = fread(h,1, 'uint32');
  Tags = struct();
  for i = 1:nrTags
    Tags(i).tag = deblank(cast(fread(h, 40, 'uint16'),'char')');
    Tags(i).index = fread(h,1,'uint32');
    switch Tags(i).tag
      case 'ExtraDataTags'
        Tags(i).IDStr = 'ExtraDataTags';
      case 'SegmentStream'
        Tags(i).IDStr = 'SegmentStream';
      case 'DataStream'
        Tags(i).IDStr = 'DataStream';
      case 'InfoChangeStream'
        Tags(i).IDStr = 'InfoChangeStream';
      case 'InfoGuids'
        Tags(i).IDStr = 'InfoGuids';
      case '{A271CCCB-515D-4590-B6A1-DC170C8D6EE2}'
        Tags(i).IDStr = 'TSGUID';
      case '{8A19AA48-BEA0-40D5-B89F-667FC578D635}'
        Tags(i).IDStr = 'DERIVATIONGUID';
      case '{F824D60C-995E-4D94-9578-893C755ECB99}'
        Tags(i).IDStr = 'FILTERGUID';
      case '{02950361-35BB-4A22-9F0B-C78AAA5DB094}'
        Tags(i).IDStr = 'DISPLAYGUID';
      case '{8E94EF21-70F5-11D3-8F72-00105A9AFD56}'
        Tags(i).IDStr = 'FILEINFOGUID';
      case '{E4138BC0-7733-11D3-8685-0050044DAAB1}'
        Tags(i).IDStr = 'SRINFOGUID';
      case '{C728E565-E5A0-4419-93D2-F6CFC69F3B8F}'
        Tags(i).IDStr = 'EVENTTYPEINFOGUID';
      case '{D01B34A0-9DBD-11D3-93D3-00500400C148}'
        Tags(i).IDStr = 'AUDIOINFOGUID';
      case '{BF7C95EF-6C3B-4E70-9E11-779BFFF58EA7}'
        Tags(i).IDStr = 'CHANNELGUID';
      case '{2DEB82A1-D15F-4770-A4A4-CF03815F52DE}'
        Tags(i).IDStr = 'INPUTGUID';
      case '{5B036022-2EDC-465F-86EC-C0A4AB1A7A91}'
        Tags(i).IDStr = 'INPUTSETTINGSGUID';
      case '{99A636F2-51F7-4B9D-9569-C7D45058431A}'
        Tags(i).IDStr = 'PHOTICGUID';
      case '{55C5E044-5541-4594-9E35-5B3004EF7647}'
        Tags(i).IDStr = 'ERRORGUID';
        case '{223A3CA0-B5AC-43FB-B0A8-74CF8752BDBE}'
        Tags(i).IDStr = 'VIDEOGUID';
      case '{0623B545-38BE-4939-B9D0-55F5E241278D}'
        Tags(i).IDStr = 'DETECTIONPARAMSGUID';
      case '{CE06297D-D9D6-4E4B-8EAC-305EA1243EAB}'
        Tags(i).IDStr = 'PAGEGUID';
      case '{782B34E8-8E51-4BB9-9701-3227BB882A23}'
        Tags(i).IDStr = 'ACCINFOGUID';
      case '{3A6E8546-D144-4B55-A2C7-40DF579ED11E}'
        Tags(i).IDStr = 'RECCTRLGUID';
      case '{D046F2B0-5130-41B1-ABD7-38C12B32FAC3}'
        Tags(i).IDStr = 'GUID TRENDINFOGUID';
      case '{CBEBA8E6-1CDA-4509-B6C2-6AC2EA7DB8F8}'
        Tags(i).IDStr = 'HWINFOGUID';
      case '{E11C4CBA-0753-4655-A1E9-2B2309D1545B}'
        Tags(i).IDStr = 'VIDEOSYNCGUID';
      case '{B9344241-7AC1-42B5-BE9B-B7AFA16CBFA5}'
        Tags(i).IDStr = 'SLEEPSCOREINFOGUID';
      case '{15B41C32-0294-440E-ADFF-DD8B61C8B5AE}'
        Tags(i).IDStr = 'FOURIERSETTINGSGUID';
      case '{024FA81F-6A83-43C8-8C82-241A5501F0A1}'
        Tags(i).IDStr = 'SPECTRUMGUID';
      case '{8032E68A-EA3E-42E8-893E-6E93C59ED515}'
        Tags(i).IDStr = 'SIGNALINFOGUID';
      case '{30950D98-C39C-4352-AF3E-CB17D5B93DED}'
        Tags(i).IDStr = 'SENSORINFOGUID';
      case '{F5D39CD3-A340-4172-A1A3-78B2CDBCCB9F}'
        Tags(i).IDStr = 'DERIVEDSIGNALINFOGUID';
      case '{969FBB89-EE8E-4501-AD40-FB5A448BC4F9}'
        Tags(i).IDStr = 'ARTIFACTINFOGUID';
      case '{02948284-17EC-4538-A7FA-8E18BD65E167}'
        Tags(i).IDStr = 'STUDYINFOGUID';
      case '{D0B3FD0B-49D9-4BF0-8929-296DE5A55910}'
        Tags(i).IDStr = 'PATIENTINFOGUID';
      case '{7842FEF5-A686-459D-8196-769FC0AD99B3}'
        Tags(i).IDStr = 'DOCUMENTINFOGUID';
      case '{BCDAEE87-2496-4DF4-B07C-8B4E31E3C495}'
        Tags(i).IDStr = 'USERSINFOGUID';
      case '{B799F680-72A4-11D3-93D3-00500400C148}'
        Tags(i).IDStr = 'EVENTGUID';
      case '{AF2B3281-7FCE-11D2-B2DE-00104B6FC652}'
        Tags(i).IDStr = 'SHORTSAMPLESGUID';
      case '{89A091B3-972E-4DA2-9266-261B186302A9}'
        Tags(i).IDStr = 'DELAYLINESAMPLESGUID';
      case '{291E2381-B3B4-44D1-BB77-8CF5C24420D7}'
        Tags(i).IDStr = 'GENERALSAMPLESGUID';
      case '{5F11C628-FCCC-4FDD-B429-5EC94CB3AFEB}'
        Tags(i).IDStr = 'FILTERSAMPLESGUID';
      case '{728087F8-73E1-44D1-8882-C770976478A2}'
        Tags(i).IDStr = 'DATEXDATAGUID';
      case '{35F356D9-0F1C-4DFE-8286-D3DB3346FD75}'
        Tags(i).IDStr = 'TESTINFOGUID';


      otherwise
        if isstrprop(Tags(i).tag, 'digit')
          Tags(i).IDStr = num2str(Tags(i).tag);
        else
          Tags(i).IDStr = 'UNKNOWN';
        end
    end
end

  obj.sections = Tags;

  %% QI index
  fseek(h, 172208,'bof');
  obj.Qi=struct();
  obj.Qi.nrEntries = fread(h,1,'uint32');
  obj.Qi.misc1 = fread(h,1,'uint32');
  obj.Qi.indexIdx = fread(h,1,'uint32');
  obj.Qi.misc3 = fread(h,1,'uint32');
  obj.Qi.LQi = fread(h,1,'uint64')';
  obj.Qi.firstIdx = fread(h,nrTags,'uint64');
  Index = struct();
  curIdx = 0;
  nextIndexPointer = indexIdx;
  fprintf('Parsing index ');
  curIdx2 = 1;
  while curIdx < obj.Qi.nrEntries
    if mod(curIdx2,20)
      fprintf('.');
    else
      fprintf('\n.');
    end

    fseek(h, nextIndexPointer, 'bof');
    nrIdx = fread(h,1, 'uint64');
    for i = 1: nrIdx
      Index(curIdx + i).sectionIdx = fread(h,1, 'uint64');
      Index(curIdx + i).offset = fread(h,1, 'uint64');
      Index(curIdx + i).blockL = fread(h,1, 'uint32');
      Index(curIdx + i).sectionL = fread(h,1, 'uint32');
    end
    nextIndexPointer = fread(h,1, 'uint64');
    curIdx = curIdx + i;
    curIdx2=curIdx2+1;

  end
  fprintf('done\n');
  obj.index = Index;
  obj.allIndexIDs = [obj.index.sectionIdx];

 %% Get PatientGUID
  info = struct();

  infoProps = { 'patientID', 'firstName','middleName','lastName',...
    'altID','mothersMaidenName','DOB','DOD','street','sexID','phone',...
    'notes','dominance','siteID','suffix','prefix','degree','apartment',...
    'city','state','country','language','height','weight','race','religion',...
    'maritalStatus'};

  ifnoIdx = Tags(find(strcmp({Tags.IDStr},'PATIENTINFOGUID'),1)).index;
  indexInstance = Index(find([Index.sectionIdx]==ifnoIdx,1));
  fseek(h, indexInstance.offset,'bof');
  guid = fread(h, 16, 'uint8'); %#ok<NASGU>
  lSection = fread(h, 1, 'uint64'); %#ok<NASGU>
%       reserved = fread(h, 3, 'uint16'); %#ok<NASGU>
  nrValues = fread(h,1,'uint64');
  nrBstr = fread(h,1,'uint64');

  for i = 1:nrValues
    id = fread(h,1,'uint64');
    switch id
      case {7,8}
        unix_time = (fread(h,1, 'double')*(3600*24)) - 2209161600;% 2208988800; %8 
        obj.segments(i).dateStr = datestr(unix_time/86400 + datenum(1970,1,1));
        value = datevec( obj.segments(i).dateStr );
        value = value([3 2 1]);
      case {23,24}
        value = fread(h,1,'double');
      otherwise
        value = 0;
    end
    info.(infoProps{id}) = value;
  end

  strSetup = fread(h,nrBstr*2,'uint64');

  for i=1:2:(nrBstr*2)
    id  = strSetup(i);
    value = deblank(cast(fread(h, strSetup(i+1) + 1, 'uint16'),'char')');
    info.(infoProps{id}) = value;
  end

  obj.patientInfo = info;

  %% Get INFOGUID
  ifnoIdx = Tags(find(strcmp({Tags.IDStr},'InfoGuids'),1)).index;
  indexInstance = Index(find([Index.sectionIdx]==ifnoIdx,1));
  fseek(h, indexInstance.offset,'bof');

  % Ignoring, is list of GUIDS in file.
%% Get SignalInfo (SIGNALINFOGUID): One per file
  SIG_struct = struct();
  sensorIdx = Tags(find(strcmp({Tags.IDStr},'SIGNALINFOGUID'),1)).index;
  indexInstance = Index(find([Index.sectionIdx]==sensorIdx,1));
  fseek(h, indexInstance.offset,'bof');
  SIG_struct.guid = fread(h, 16, 'uint8');
  SIG_struct.name = fread(h, obj.ITEMNAMESIZE, '*char');
  unkown = fread(h, 152, '*char');         %#ok<NASGU>
  fseek(h, 512, 'cof');
  nrIdx = fread(h,1, 'uint16');  %783
  misc1 = fread(h,3, 'uint16'); %#ok<NASGU>
  obj.sigInfo = struct();
  for i = 1: nrIdx
    obj.sigInfo(i).sensorName = deblank(cast(fread(h, obj.LABELSIZE, 'uint16'),'char')');
    obj.sigInfo(i).transducer = deblank(cast(fread(h, obj.UNITSIZE, 'uint16'),'char')');
    obj.sigInfo(i).guid = fread(h, 16, '*uint8');
    obj.sigInfo(i).bBiPolar = logical(fread(h, 1 ,'uint32'));
    obj.sigInfo(i).bAC = logical(fread(h, 1 ,'uint32'));
    obj.sigInfo(i).bHighFilter = logical(fread(h, 1 ,'uint32'));
    obj.sigInfo(i).color =  fread(h, 1 ,'uint32');
    reserved = fread(h, 256, '*char'); %#ok<NASGU>
  end


%% Get CHANNELINFO (CHANNELGUID)
  CH_struct = struct();
  sensorIdx = Tags(find(strcmp({Tags.IDStr},'CHANNELGUID'),1)).index;
  indexInstance = Index(find([Index.sectionIdx]==sensorIdx,1));
  fseek(h, indexInstance.offset,'bof');
  CH_struct.guid = fread(h, 16, 'uint8');
  CH_struct.name = fread(h, obj.ITEMNAMESIZE, 'uint8');
  fseek(h, 152, 'cof');
  CH_struct.reserved = fread(h, 16, 'uint8');
  CH_struct.deviceID = fread(h, 16, 'uint8');
  fseek(h, 488, 'cof');
  nrIdx = fread(h,2, 'uint32');  %783
  obj.chInfo = struct();
  for i = 1:nrIdx(2)
    obj.chInfo(i).sensor = deblank(cast(fread(h, obj.LABELSIZE, 'uint16'),'char')');
    obj.chInfo(i).samplingRate = fread(h,1,'double');
    obj.chInfo(i).bOn = logical(fread(h, 1 ,'uint32'));
    obj.chInfo(i).lInputID = fread(h, 1 ,'uint32');
    obj.chInfo(i).lInputSettingID = fread(h,1,'uint32');
    obj.chInfo(i).reserved = fread(h,4,'char');
    fseek(h, 128, 'cof');
  end

  curIdx = 0;
  for i = 1: length(obj.chInfo)
    if obj.chInfo(i).bOn
     obj.chInfo(i).indexID = curIdx;
     curIdx = curIdx+1;
    else
      obj.chInfo(i).indexID = -1;
    end
  end
   %% Get TS info (TSGUID):(One per segment, last used if no new for segment)
  TS_struct = struct();
  sensorIdx = Tags(find(strcmp({Tags.IDStr},'TSGUID'),1)).index;
  indexInstance = Index([Index.sectionIdx]==sensorIdx);

  if length(indexInstance) > 1
    warning(['Multiple TSinfo packets detected; using first instance '...
      ' ac for all segments. See documentation for info.']);
  end

  TSInfo = struct();
  for iTS = 1: length(indexInstance)
       fseek(h, indexInstance(iTS).offset,'bof');

    % find guid
    aux =  fread(h, indexInstance(iTS).sectionL./2, 'uint16');
    guid = [52427 41585 20829 17808 41398 6108 36108 57966];
%         display(sprintf('%i',iTS));
    startGuid = strfind(aux', guid);

    % Sometimes the block contains multiple headers randomly, so far
    % the best bet has been to read the block starting on the following
    % ideces. 
    if startGuid
      switch length(startGuid)
        case 1
          useIdx = 1;
        case 2
          useIdx = 1;
        otherwise
          useIdx = 2;
      end
      guidOffset = indexInstance(iTS).offset + (startGuid(useIdx)-1)*2;
    else
      error('Can''t find TSInfo header in TSInfo block, blame Nicolet');
    end
    fseek(h, guidOffset,'bof');
TS_struct.guid = fread(h, 16, 'uint8'); % [CBCC 71A2 5D51 9045...] {A271CCCB-515D-4590-B6A1-DC170C8D6EE2}
    TS_struct.name = fread(h, obj.ITEMNAMESIZE, '*char');
    fseek(h, 152, 'cof');
    TSInfo(iTS).notchFreq = fread(h, 1, 'double');
    fseek(h, 512, 'cof');
    nrIdx = fread(h,2, 'uint32');  %783

    for i = 1: nrIdx(2)
      TSInfo(iTS).series(i).label = deblank(cast(fread(h, obj.TSLABELSIZE, 'uint16'),'char')');
      fZero = find(double(TSInfo(iTS).series(i).label)==0,1);
      if fZero; TSInfo(iTS).series(i).label = TSInfo(iTS).series(i).label(1:fZero-1);end

      TSInfo(iTS).series(i).activeSensor = deblank(cast(fread(h, obj.LABELSIZE, 'uint16'),'char')');
      fZero = find(double(TSInfo(iTS).series(i).activeSensor)==0,1);
      if fZero; TSInfo(iTS).series(i).activeSensor = TSInfo(iTS).series(i).activeSensor(1:fZero-1);end

      TSInfo(iTS).series(i).refSensor = deblank(cast(fread(h, obj.LABELSIZE, 'uint16'),'char')');
      fZero = find(double(TSInfo(iTS).series(i).refSensor)==0,1);
      if fZero; TSInfo(iTS).series(i).refSensor = TSInfo(iTS).series(i).refSensor(1:fZero-1);end


      TSInfo(iTS).series(i).dLowCut = fread(h,1,'double');
      TSInfo(iTS).series(i).dHighCut = fread(h,1,'double');
      TSInfo(iTS).series(i).dSamplingRate = fread(h,1,'double');
      TSInfo(iTS).series(i).dResolution = fread(h,1,'double');
      TSInfo(iTS).series(i).bMark = logical(fread(h, 1 ,'uint32'));
      TSInfo(iTS).series(i).bNotch = logical(fread(h, 1 ,'uint32'));

      tmp3 = find(strcmp(num2str(i-1),{obj.sections.tag}),1);
      if ~isempty(tmp3)
        TSInfo(iTS).series(i).ID = obj.sections(tmp3).index;
      end

      fseek(h, 256, 'cof');
    end


  end

obj.tsInfo = TSInfo;

  % -- -- -- 

  %% Get Segment Start Times
  segmentIdx = Tags(find(strcmp({Tags.IDStr}, 'SegmentStream'),1)).index;
  indexIdx = find([Index.sectionIdx] == segmentIdx, 1);
  segmentInstance = Index(indexIdx);

  nrSegments = segmentInstance.sectionL/152;
  fseek(h, segmentInstance.offset,'bof');
  obj.segments = struct();
  for i = 1: nrSegments
    unix_time = (fread(h,1, 'double')*(3600*24)) - 2209161600;% 2208988800; %8 
    obj.segments(i).dateStr = datestr(unix_time/86400 + datenum(1970,1,1));
    datev = datevec( obj.segments(i).dateStr );
    obj.segments(i).startDate = datev(1:3);
    obj.segments(i).startTime = datev(4:6);
    fseek(h, 8 , 'cof'); %16
    obj.segments(i).duration = fread(h,1, 'double');%24
    fseek(h, 128 , 'cof'); %152
  end
% Get nrValues per segment and channel
  for iSeg = 1:length(obj.segments)

    % Add Channel Names to segments
    obj.segments(iSeg).chName = {obj.tsInfo(obj.useTSinfoIdx).series.label};
    obj.segments(iSeg).refName = {obj.tsInfo(obj.useTSinfoIdx).series.refSensor};
    obj.segments(iSeg).samplingRate = [obj.tsInfo(obj.useTSinfoIdx).series.dSamplingRate];
    obj.segments(iSeg).scale = [obj.tsInfo(obj.useTSinfoIdx).series.dResolution];

  end

  % Close File
  fclose(h);

  %output the important info for data collection
  fprintf(strcat('MRN:',obj.patientInfo.altID,'\n'))
  for i = 1:length(obj.segments)
        fprintf('segment:%g;duration:%g\n',i,obj.segments(i).duration)
  end

  %save header struct
  saveName=strcat(obj.patientInfo.altID,'_header');
  if exist(strcat(saveName,'.mat'),'file')
