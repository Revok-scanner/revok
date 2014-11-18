#
# Reflected XSS Attack Checking Module
# Check whether X-XSS-PROTECTION HTTP header is set to mitigate reflected XSS attacks.
#
require 'json'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/report.ut.rb"

class AntiReflectionChecker < Revok::Module
  include ReportUtils
  def initialize(load_from_file = false, session_file = "")
    info_register("AntiReflectionChecker", {"group_name" => "default",
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
    header_found = false
    Log.info( "Checking for X-XSS-PROTECTION header...")
    begin
      @session_data = @datastore['session'] if @session_data == nil
      @config = @datastore['config']
      data = JSON.parse(@session_data, {create_additions:false})
      config = JSON.parse(@config, {create_additions:false})
      responses = data['responses']
      responses.each_pair do |k,v|
        if v.scan(/X-XSS-PROTECTION: *1/i) !=[]
          next if not data['requests'][k].lines.first.include? config['whitelist'][0]
          Log.info( "Found X-XSS-PROTECTION is being enabled in response ##{k}" )
          header_found = true
          break
        end
      end
      if header_found == false
        Log.warn( "X-XSS-PROTECTION is not found")
      end
    rescue => excep
      Log.error( "AntiReflectionChecker excep  is #{excep}" )
    end#begin
  end #run
end
