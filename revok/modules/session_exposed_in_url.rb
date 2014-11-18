#
# Session Exposed in Url Module
# Check whether session id is exposed in requested URLs.
#

require 'json'
require 'typhoeus'
require 'net/http'
require 'rex'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/report.ut.rb"
require "#{Revok::Config::MODULES_DIR}/lib/session_check.rb.ut.rb"

include Sess
class SessionExposureCheckor < Revok::Module
  include ReportUtils
  def initialize(load_from_file = false, session_file = "")
    info_register("SessionExposureCheckor", {"group_name" => "default",
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
  
#  def exposure_check
  def run
    session_val = String.new
    url = String.new
    vul = Array.new
    begin
      if @session_id != nil
        session = JSON.parse(@session_data, {create_additions:false})
        cookies = session['cookie'].gsub(/Cookie:/, "").split(";")
        cookies.each do |k|
          if k.include? "#{@session_id}="
            session_val = k.gsub(/#{@session_id}=/, "").strip 
            break
          end
        end
        session['requests'].each_pair do |k, v|
          request = v.split("\r\n")[0].gsub(/HTTP\/1.*/, "")
          if request.include? session_val
            vul.push(request)
          end
        end
      end
    rescue => exp
      Log.error("#{exp}")
      return
    end

    if vul.size == 0
      abstain
      Log.info( "No session ID found in urls"  )
    else
      vul=vul.uniq
      vul.each do |k|
        Log.info( "Session exposed in url of request: #{k}" )
        k = k.gsub(/POST/, "POST request for").gsub(/GET/, "GET request for")
        list("#{k}")  
      end
      Log. warn({"name" => "session_exposed_in_url"})
    end
    Log.info("exposure_check is Done")
  end
end
