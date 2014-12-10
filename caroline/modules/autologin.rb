require 'open3'
require 'json'
require 'socket'
require 'timeout'
require 'core/module'

class Autologin < Revok::Module

  def cleanProcs
    mitmdump = `ps -ef | grep mitmdump | grep -v grep | awk '{print $2}'`.to_i
    Process.kill 'KILL', mitmdump if mitmdump > 0
    phantom = `ps -ef | grep phantomjs | grep -v grep | awk '{print $2}'`.to_i
    Process.kill 'KILL', phantom if phantom > 0
  end

  def initialize
    info_register("Autologin", {"group_name" => "system", 
                                "group_priority" => 0,
                                "priority" => 0,
                                "required" => true})
    @autotime = 30
  end

  def run
    @config = @datastore['config']
    config = JSON.parse(@config, {create_additions:false})
    if config['logtype'] != "normal" or config['positions']['button']['x'] > 0
      Log.info("No need to autologin")
      return
    end

    cleanProcs

    mitm_in, mitm_out, mitm_err, mitm_thd = Open3.popen3("mitmdump")
    mitm_in.close
    ready = false
    until ready
      begin
        TCPSocket.new('localhost',8080)
        ready = true
      rescue Errno::ECONNREFUSED
        ready = false
      end
    end

    Log.info("mitmdump is started")

    phantom_in, phantom_out, phantom_err = Open3.popen3("phantomjs --proxy=localhost:8080 --ignore-ssl-errors=true --ssl-protocol=any #{Revok::Config::MODULES_DIR}/js/autologin.js")
    phantom_in.puts @config
    phantom_in.close

    Log.info("phantomjs is started")
    Log.info("Detecting position of the login form...")

    new_conf = nil
    begin
      Timeout::timeout(@autotime) do
        new_conf = phantom_out.gets
      end
    rescue Timeout::Error
      sock = nil
      begin
        Log.info("Asking phantomjs to stop...")
        sock = TCPSocket.new '127.0.0.1', 4447
        sock.write("GET / HTTP/1.1\n\n")
      rescue
        Log.warn("phantomjs is probably still running")
      ensure
        sock.close() if not sock.nil?
      end
    end

    Log.debug("phantom_out: #{phantom_out.read}")
    Log.debug("phantom_err: #{phantom_err.read}")

    phantom_out.close
    phantom_err.close

    if (not new_conf.nil?) then
      new_conf.chomp!
      valid = false
      begin
        JSON.parse(new_conf, {create_additions:false})
        valid = true
      rescue JSON::ParserError
        valid = false
      end
      @datastore['config'] = new_conf if valid
    end

    begin
      mitmdump = `ps -ef | grep mitmdump | grep -v grep | awk '{print $2}'`.to_i
      Log.info("Asking mitmdump to stop...") if mitmdump > 0
      Process.kill 'INT', mitmdump if mitmdump > 0
    rescue
      Log.warn("mitmdump is probably still running")
    end

    Log.debug("mitm_err: #{mitm_err.read}")
    Log.debug("mitm_out: #{mitm_out.read}")

    mitm_err.close
    mitm_out.close

    Log.info("autologin completed")

  end

  attr_accessor  :autotime, :config

end
