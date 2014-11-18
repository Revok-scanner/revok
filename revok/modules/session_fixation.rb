#
# Session Fixation Checking Module.
# Check whether session id is refreshed after login to prevent session fixation.
#

require 'json'
require 'typhoeus'
require 'net/http'
require 'rex'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/report.ut.rb"
require "#{Revok::Config::MODULES_DIR}/lib/session_check.rb.ut.rb"

include Sess
class SessionFixationCheckor < Revok::Module
  include ReportUtils

  def initialize(load_from_file = false, session_file = "")
    info_register("SessionFixationCheckor", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10})
    if(load_from_file)
      begin
        @session_data = File.open(session_file, 'r').read
      rescue => exp
        @session_data = ""
        Log.warn(exp.to_s)
        Log.debug("#{exp.backtrace}")
      end
    end
  end
 
  def run
    begin
      @session_data = @datastore['session'] if @session_data == nil
      @config = @datastore['config']
      @session = JSON.parse(@session_data, {create_additions:false})
      @config = JSON.parse(@config, {create_additions:false})
      result = true
      result = sess_fix
    rescue => excep
      Log.error( excep.to_s )
      return
    end

    if result == true
      Log.info("")
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
