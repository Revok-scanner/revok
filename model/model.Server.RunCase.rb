$ROOT_PATH=ENV['ROOT_PATH'] if not $ROOT_PATH
$: << "#{$ROOT_PATH}/activemq/"
$: << "#{$ROOT_PATH}/model/"
$: << "#{$ROOT_PATH}/db/"
$: << "#{$ROOT_PATH}/revok/"

require 'model.Bean.RunCase'
require 'dao.activemq.RunCase'
require 'dao.psql.RunCase'
require 'time'
require 'revok'

include Revok

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
  end
	
  def clean
    @runCaseDaoActivemq.clean
    @runCaseDaoPsql.clean
  end
	
  def run(runCase)
    begin
      Revok.run_case(runCase)
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
