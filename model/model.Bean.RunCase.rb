class ScanConfig
  
  FLAG_SCREENSHOT=0x00000001;
  FLAG_SENDEMAIL=0x00000002;
  FLAG_AUTOLOGIN=0x00000004;
  FLAG_CRAWLER=0x00000008;
  
  FLAG_SITEMAP=0x00000010;
  FLAG_CORSS=0x00000020;
  FLAG_ACCESS_ADMIN=0x00000040;
  FLAG_PATH_TRAVERSAL=0x00000080;
  
  FLAG_SESSION_CHECK=0x00000100;
  FLAG_COOKIE_CHECK=0x00000200;
  FLAG_MIME_TYPE=0x00000400;
  FLAG_FRAME_BUSTING=0x00000800;
  
  FLAG_METHOD_CHECK=0x00001000;
  FLAG_AUTOCOMPLETE=0x00002000;
  FLAG_BRUTEFORCE=0x00004000;
  FLAG_ANTI_REFLECTION=0x00008000;
  
  
  FLAG_REDIR_CHECK=0x00010000;
  FLAG_SSL_CHECK=0x00020000;
  FLAG_SQLI_CHECK=0x00040000;
  FLAG_XSSI_CHECK=0x00080000;
  
  FLAG_RENDER=0x00100000;
    
  def initialize(config)
    @config=config
  end
  
  def screenshot
    @config&FLAG_SCREENSHOT
  end
   
  def sendemail
    @config&FLAG_SENDEMAIL
  end
  
  def autologin
    @config&FLAG_AUTOLOGIN
  end
  
  def crawler
    @config&FLAG_CRAWLER
  end 
  
  def sitemap
    @config&FLAG_SITEMAP
  end
  
  def corss
    @config&FLAG_CORSS
  end
  
  def access_admin
    @config&FLAG_ACCESS_ADMIN
  end
  def path_traversal
    @config&FLAG_PATH_TRAVERSAL
  end
  
  def session_check
    @config&FLAG_SESSION_CHECK
  end
  
  def cookie_check
    @config&FLAG_COOKIE_CHECK
  end
  
  def mime_type
    @config&FLAG_MIME_TYPE
  end
  
  def frame_busting
    @config&FLAG_FRAME_BUSTING
  end
    def method_check
    @config&FLAG_METHOD_CHECK
  end
  
  def autocomplete
    @config&FLAG_AUTOCOMPLETE
  end
    def bruteforce
    @config&FLAG_BRUTEFORCE
  end
  
  def anti_reflection
    @config&FLAG_ANTI_REFLECTION
  end
  
  def redir_check
    @config&FLAG_REDIR_CHECK
  end
    
  def ssl_check
    @config&FLAG_SSL_CHECK
  end
  
  def sqli_check
    @config&FLAG_SQLI_CHECK
  end
  
  def xssi_check
    @config&FLAG_XSSI_CHECK
  end
      
  def render
    @config&FLAG_RENDER
  end
  
end

class RunCase
  def initialize(idOrDict)
    if idOrDict.class==Hash
      @id=idOrDict['id']
      @process=idOrDict['process']
      @scanConfig=idOrDict['scanConfig']
      @targetInfo=idOrDict['targetInfo']
      @log=idOrDict['log']
      @startTime=idOrDict['startTime']
      @endTime=idOrDict['endTime']
      @requestor=idOrDict['requestor']
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
