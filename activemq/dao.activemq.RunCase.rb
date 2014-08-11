$ROOT_PATH=ENV['ROOT_PATH']
$: << "#{$ROOT_PATH}/activemq/"
$: << "#{$ROOT_PATH}/model/"

require 'model.Bean.RunCase'
require 'activemqHelper'
require 'json'
require 'timeout'

class RunCaseDaoActivemq
  def initialize
    @mqHelper=ActivemqHelper.new
  end
  
  def clean
    @mqHelper.clean if @mqHelper
    @message_id=nil
  end
  
  def putRunCase(runCase)
    begin 
      job = JSON.generate(runCase.to_dict).to_s 
      @mqHelper.put(job)
      return runCase
    rescue => exp
      puts $!
      puts "#{exp.backtrace.join("\n")}"  
      puts "putRunCase Error!"
      return nil
    end
  end

  def ackRunCase
      @mqHelper.conn.ack(@message_id) if @message_id
  end

  def getRunCase
    begin
      msg=@mqHelper.conn.receive
      runCaseDict=JSON.parse(msg.body, {create_additions:false}) 
      @message_id= msg.headers['message-id']
      result=RunCase.new(runCaseDict)
    rescue => exp
      puts $!
      puts "getRunCaseError"
      result=nil
    end
    return result
  end

end
