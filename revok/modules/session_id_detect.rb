
require 'json'
require 'typhoeus'
require 'net/http'
require 'rex'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/report.ut.rb"
require "#{Revok::Config::MODULES_DIR}/lib/session_check.rb.ut.rb"

include Sess
class SessionIdDetect < Revok::Module
  include ReportUtils
  def initialize(load_from_file = false, session_file = "")
    info_register("SessionIdDetect", {"group_name" => "default",
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
     Log.info("here")
     begin
      
      session_id = String.new()
      cookies = Array.new()
      requests = Hash.new()
      login_redir = Array.new()
      login_request = 0
      session = JSON.parse(@session_data, {create_additions:false})
      config = JSON.parse(@config, {create_additions:false})
      cookies = session['cookie'].scan(/Cookie:(.*?)$/)[0][0].split(";")
      requests = session['requests']
      logtype = config['logtype']
      username = config['username']
      password = config['password']
      login = config['login']
      login_page = login.split("/")[login.split("/").size-1]
    rescue => exp
      Log.error("#{exp}")
    end
    if logtype == "normal"
      #Scan for login request    
      requests.each_pair do |k,v|
        body = v.gsub(v.split("\r\n\r\n")[0], "")
        if v.scan(/^POST/)!=[] and body!= "" and body.scan(/#{username}/)!=[] and body.scan(/#{password}/)!=[]
          login_request = k.to_i
          @login_request = login_request
          $datastore['login_request'] = @login_request
          break
        end
      end
 
      #Scan for the first request after login 
      if login_request > 0 and requests["#{login_request+1}"] != nil
        req  = requests["#{login_request+1}"]
      else
        Log.info( "Login request or request after login isn't scanned." )
        return
      end
    end

    #Detect session ID from cookies
    cookies.each do |k|
      k=k.split("=")[0]
      if logtype == "normal"
        test_req = req.gsub(/#{k}=.*?;|#{k}=.*?$/, "")
        url=req.match(/\s(http.*?)\sHTTP\//)[1]
        uri=URI(url)
        host=uri.host
        port = uri.port
        context = {}
        ssl = (uri.scheme=='https'?true:false)
        ssl_version = nil
        proxies = nil
        conn=Rex::Proto::Http::Client.new(host,port, context, ssl, ssl_version, proxies)

        begin
          resp = conn.send_recv(test_req, 30)
        rescue
          Log.error( "#{$!}" )
        end

        if resp.headers['Location'] != nil
          location = resp.headers['Location']
          login_redir = location.scan(/#{login}|#{login_page}/)
        end

        if (resp.code > 300 and login_redir != []) or resp.code == 403 #drupal returns 403
          session_id = k.gsub(/=.*?$/, "").strip
          break
        end
      
      elsif logtype == "basic"
        session_id = k.gsub(/=.*?$/, "").strip if k.scan(/sess/i) != []
        break
      end
    end
    if session_id != ""
      @session_id=session_id
      $datastore['session_id'] = session_id
      Log.info( "The key of session ID is detected: #{session_id}" )
    else
      Log.info( "Session ID isn't detected" )
    end
  end
