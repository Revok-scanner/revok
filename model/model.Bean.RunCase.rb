class RunCase
  def initialize(idOrDict)
    if idOrDict.class==Hash
      @id=idOrDict['id']
      @uid=idOrDict['uid']
      @process=idOrDict['process']
      @scanConfig=idOrDict['scanConfig']
      @targetInfo=idOrDict['targetInfo']
      @log=idOrDict['log']
      @startTime=idOrDict['startTime']
      @endTime=idOrDict['endTime']
      @requestor=idOrDict['requestor']
      @type = idOrDict['type']
    end
  end

  def to_dict
    runDict={}
    runDict['id']=@id if @id
    runDict['process']=@process if @process
    runDict['log']=@log if @log
    runDict['targetInfo']=@targetInfo if @targetInfo
    runDict['scanConfig']=@scanConfig if @scanConfig
    runDict['startTime']=@startTime if @startTime
    runDict['endTime']=@endTime if @endTime
    runDict['requestor']=@requestor if @requestor
    runDict['type']=@type if @type
    runDict['uid']=@uid if @uid
    return runDict
  end

  def id
    @id
  end

  def process
    @process
  end

  def setProcess(process)
    @process=process
  end

  def log
    @log
  end

  def setLog(log)
    @log=log
  end

  def targetInfo
    @targetInfo
  end

  def scanConfig
    @scanConfig
  end

  def scanConfigObj
    return @scanConfigObj if @scanConfigObj
    @scanConfigObj=ScanConfig.new(@scanConfig)
    return @scanConfigObj
  end

  def startTime
    @startTime
  end

  def endTime
    @endTime
  end

  def requestor
    @requestor
  end

  def setStartTime(time)
    @startTime=time
  end

  def setEndTime(time)
    @endTime=time
  end

  def setTargetInfo(targetInfo)
    @targetInfo=targetInfo
  end

  def setScanConfig(scanConfig)
    @scanConfig=scanConfig
  end

  def setRequestor(requestor)
    @requestor=requestor
  end

end
