$ROOT_PATH=ENV['ROOT_PATH'] if not $ROOT_PATH
$: << "#{$ROOT_PATH}/model/"
$: << "#{$ROOT_PATH}/db/"

require 'model.Bean.RunCase'
require 'psqlHelper.rb'

class RunCaseDaoPsql
  def initialize
    @pgHelper=PsqlHelper.new
  end
  
  def clean
    @pgHelper.clean if @pgHelper
  end
  
  def putRunCase(runCase,force=false)
    exists=true
    begin
      sql="select * from runcases where id = '#{runCase.id}';"
      result=@pgHelper.conn.exec(sql)
      if result.num_tuples<1
         exists=false
      end
 
      # remove sensitive data
      config_json=Base64.decode64(runCase.targetInfo)
      config_dict=JSON.parse(config_json,{create_additions:false})
      config_dict.delete("username")
      config_dict.delete("password")
      targetInfo=Base64.encode64(config_dict.to_json)
     
      if not exists
        sql='insert into runcases(id,process,scanconfig,targetinfo,log,starttime,endtime,requestor) values($1, $2, $3, $4, $5, $6, $7, $8) '
        param=[runCase.id,runCase.process,runCase.scanConfig,targetInfo,runCase.log,runCase.startTime,runCase.endTime,config_dict['email']]
        result=@pgHelper.conn.exec(sql,param)
        return result
      elsif force
        sql="update runcases set process=$2,scanconfig=$3,targetinfo=$4,log=$5,starttime=$6,endtime=$7,requestor=$8 where id=$1;"
        param=[runCase.id,runCase.process,runCase.scanConfig,targetInfo,runCase.log,runCase.startTime,runCase.endTime,config_dict['email']]
        result=@pgHelper.conn.exec(sql,param)
        return result
      else
        raise "runcase id must be unique!"
      end
    rescue => exp
      puts $!
      puts "#{exp.backtrace.join("\n")}"  
      puts "putRunCase Error!"
      return nil
    end
  end

  def getRunCaseById(id)
    sql="select * from runcases where id = '#{id}';"
    begin
      result=@pgHelper.conn.exec(sql)
      return nil if not result or result.num_tuples!=1
      return RunCase.new(result[0])
    rescue => exp
      puts $!
      puts "#{exp.backtrace.join("\n")}"  
      puts "getRunCaseError"
      return nil
    end
  end
	
end
