$ROOT_PATH=ENV['ROOT_PATH'] if not $ROOT_PATH
$: << "#{$ROOT_PATH}/activemq/"
$: << "#{$ROOT_PATH}/model/"
$: << "#{$ROOT_PATH}/db/"
$: << "#{$ROOT_PATH}/caroline/"

require 'model.Bean.RunCase'
require 'dao.activemq.RunCase'
require 'dao.psql.RunCase'
require 'time'
require 'revok'

class RunCaseServer
  def initialize
    @default_option={
      "id"=>Time.now.to_f.to_s,
      "process"=>"----------",
      "scanConfig"=>0,
      "targetInfo"=>"",
      "log"=>"",
      "startTime"=>Time.now.to_i,
      "endTime"=>0,
      "requestor"=>"revok@example.com",
    }
    @runCaseDaoActivemq=RunCaseDaoActivemq.new
    @runCaseDaoPsql=RunCaseDaoPsql.new
    @framework = Revok::Framework.new
    @framework.load_modules
    @framework.init_modules
  end
	
  def clean
    @runCaseDaoActivemq.clean
    @runCaseDaoPsql.clean
  end

  def send_modules_list(uid = "")
    list = Hash.new
    if (@framework)
      @framework.modules.each do |key, _module|
        if (!_module.info['required'])
          list[key] = _module.info['detail']
        end
      end
    end
    msg = Hash.new
    msg['type'] = "modules_list"
    msg['uid'] = uid
    msg['list'] = list
    queue_client = Revok::ActiveMQClient.new
    puts "Connecting to messages queue..."
    queue_client.connect
    puts "Publishing modules list"
    queue_client.publish(JSON.generate(msg).to_s)
  end
	
  def run(runCase)
    begin
      executor = Revok::ModuleExecutor.new(runCase, @framework.modules)
      executor.gen_exec_list_all
      executor.execute
    rescue => exp
      puts $!
      puts "#{exp.backtrace.join("\n")}"
    end
  end
	
  def showProcess(runCase)
    runCase.process
  end
	
  def showRunCase(runCase)
    targetinfo_=runCase.targetInfo
    runCase.setTargetInfo("******")
    str_=JSON.generate(runCase.to_dict).to_s
    runCase.setTargetInfo(targetinfo_)
    return str_
  end
	
  def validate(runCase)
    true
  end
	
  def exists?(id)
    @runCaseDaoPsql.getRunCaseById(id)? true:false
  end

  def ackRunCaseToQueue
    @runCaseDaoActivemq.ackRunCase
  end

  def getRunCaseFromQueue
    @runCaseDaoActivemq.getRunCase
  end

  def putRunCaseToQueue(runCase)
    @runCaseDaoActivemq.putRunCase(runCase)
  end
	
  def saveRunCaseToDB(runCase,force=false)
    @runCaseDaoPsql.putRunCase(runCase,force) 
  end
	
  def loadRunCaseFromDBByID(id)
    @runCaseDaoPsql.getRunCaseById(id)
  end

  def createRunCase(option={})
    RunCase.new(@default_option.merge(option))
  end
end
