#
# Session Fixation Checking Module.
# Check whether session id is refreshed after login to prevent session fixation.
#

$: << "#{File.dirname(__FILE__)}/lib/"
require 'report.ut'
require 'json'
require 'typhoeus'
require 'net/http'
require 'rex'
require 'session_check.rb.ut'

include Sess
class SessionFixationCheckor 
  include ReportUtils
  def initialize(config=$datastore['config'],session_data=$datastore['session'],flag='s',session_id=$datastore['session_id'],login_request=$datastore['login_request'])
    @config=config
    @session_id=session_id
    @login_request=login_request
    if flag=='f'
      begin
        @session_data=File.open(session_data,'r').read 
      rescue =>exp
        log exp.to_s 
        @session_data=""
      end
    elsif flag=="s"
      @session_data=session_data
    else
      log 'unknow flag' 
      return nil
    end
  end
 
  def fixation_check
    @session = JSON.parse(@session_data, {create_additions:false})
    @config = JSON.parse(@config, {create_additions:false})
    result = true
    begin
      result = sess_fix
    rescue => excep
      error
      log excep.to_s 
    end

    if result == true
      abstain
    else
      if @config['logtype'] == 'normal'
        url = "POST request for #{@config['login']}"
      else
        url = "GET request for #{@config['target']}"
      end
      warn({"url" => url,"name"=>"session_fixation"})
    end
  end
   
end
